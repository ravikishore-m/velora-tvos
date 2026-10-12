#!/bin/zsh
#
# Swiftfin is subject to the terms of the Mozilla Public
# License, v2.0. If a copy of the MPL was not distributed with this
# file, you can obtain one at https://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2026 Jellyfin & Jellyfin Contributors
#
# Keeps RKPlex on the Apple TV in step with a git branch: deploys when the branch moves,
# and re-signs before a free Apple ID's 7-day provisioning profile lapses.
# Builds in its own worktree, so the working copy is never touched.
#
# Run by launchd (see install-launch-agent.sh), or by hand. `--force` deploys regardless.
#
# Environment:
#   RKPLEX_BRANCH         branch to deploy; follows its upstream when it has one
#   RKPLEX_DEVICE         Apple TV identifier for devicectl
#   RKPLEX_DESTINATION    Apple TV UDID for xcodebuild
#   RKPLEX_MAX_AGE_DAYS   rebuild after this many days without changes (default 5)

set -euo pipefail

SCRIPT_DIR=${0:A:h}
REPO=${RKPLEX_REPO:-${SCRIPT_DIR:h:h}}
BRANCH=${RKPLEX_BRANCH:?set RKPLEX_BRANCH}
DEVICE=${RKPLEX_DEVICE:?set RKPLEX_DEVICE}
DESTINATION=${RKPLEX_DESTINATION:?set RKPLEX_DESTINATION}
MAX_AGE_DAYS=${RKPLEX_MAX_AGE_DAYS:-5}

STATE_DIR="$HOME/Library/Application Support/RKPlexDeploy"
CACHE_DIR="$HOME/Library/Caches/RKPlexDeploy"
LOG_DIR="$HOME/Library/Logs/RKPlexDeploy"
WORKTREE="$CACHE_DIR/worktree"
DERIVED_DATA="$CACHE_DIR/DerivedData"
SIGNING_CONFIG="XcodeConfig/DevelopmentTeam.xcconfig"

export DEVELOPER_DIR=${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/usr/local/bin:$PATH"

mkdir -p "$STATE_DIR" "$CACHE_DIR" "$LOG_DIR"
find "$LOG_DIR" -name 'build-*.log' -mtime +30 -delete 2>/dev/null || true

log() { print -r -- "$(date '+%F %T') $*"; }

notify() {
    osascript -e "display notification \"$2\" with title \"RKPlex deploy\" subtitle \"$1\"" >/dev/null 2>&1 || true
}

LOCK="$CACHE_DIR/lock"
if ! mkdir "$LOCK" 2>/dev/null; then
    log "Another deploy is running"
    exit 0
fi
trap 'rmdir "$LOCK" 2>/dev/null' EXIT

fail() {
    log "FAILED: $1"
    notify "Deploy failed" "$1"
    exit 1
}

force=0
[[ ${1:-} == --force ]] && force=1

# Desired state: the upstream tip when the branch tracks one, otherwise the local branch
upstream=$(git -C "$REPO" rev-parse --abbrev-ref "$BRANCH@{upstream}" 2>/dev/null || true)
if [[ -n $upstream ]]; then
    git -C "$REPO" fetch --quiet "${upstream%%/*}" || log "Fetch failed, using the last fetched $upstream"
    target=$(git -C "$REPO" rev-parse "$upstream")
else
    target=$(git -C "$REPO" rev-parse --verify --quiet "refs/heads/$BRANCH") || fail "No branch $BRANCH"
fi

deployed=$(cat "$STATE_DIR/deployed-sha" 2>/dev/null || true)
deployed_at=$(cat "$STATE_DIR/deployed-at" 2>/dev/null || echo 0)
age_days=$(( ($(date +%s) - deployed_at) / 86400 ))

if (( force )); then
    reason="forced"
elif [[ $target != "$deployed" ]]; then
    reason="new commit ${target:0:8}"
elif (( age_days >= MAX_AGE_DAYS )); then
    reason="re-signing after $age_days days"
else
    log "Up to date at ${target:0:8}, signed $age_days days ago"
    exit 0
fi

log "Deploying: $reason"

xcrun devicectl device info details --device "$DEVICE" --timeout 60 >/dev/null 2>&1 \
    || fail "Apple TV is not reachable; will retry next run"

if [[ -e $WORKTREE/.git ]]; then
    git -C "$WORKTREE" checkout --quiet --detach --force "$target"
    git -C "$WORKTREE" clean -fdxq
else
    git -C "$REPO" worktree prune
    git -C "$REPO" worktree add --quiet --detach "$WORKTREE" "$target"
fi

[[ -f $REPO/$SIGNING_CONFIG ]] || fail "Missing $SIGNING_CONFIG in the repository"
cp "$REPO/$SIGNING_CONFIG" "$WORKTREE/$SIGNING_CONFIG"

build_log="$LOG_DIR/build-$(date '+%Y%m%d-%H%M%S').log"
log "Building ${target:0:8}, log at $build_log"

xcodebuild \
    -project "$WORKTREE/Swiftfin.xcodeproj" \
    -scheme "Swiftfin tvOS" \
    -configuration Release \
    -destination "id=$DESTINATION" \
    -derivedDataPath "$DERIVED_DATA" \
    -allowProvisioningUpdates \
    -skipMacroValidation \
    -skipPackagePluginValidation \
    build >"$build_log" 2>&1 \
    || fail "Build failed, see $build_log"

app="$DERIVED_DATA/Build/Products/Release-appletvos/Swiftfin.app"
xcrun devicectl device install app --device "$DEVICE" "$app" >>"$build_log" 2>&1 \
    || fail "Install failed, see $build_log"

print -r -- "$target" >"$STATE_DIR/deployed-sha"
date +%s >"$STATE_DIR/deployed-at"

log "Deployed ${target:0:8}"
notify "Deployed to Apple TV" "${target:0:8}: $reason"
