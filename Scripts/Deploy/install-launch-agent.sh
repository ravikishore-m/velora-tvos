#!/bin/zsh
#
# Swiftfin is subject to the terms of the Mozilla Public
# License, v2.0. If a copy of the MPL was not distributed with this
# file, you can obtain one at https://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2026 Jellyfin & Jellyfin Contributors
#
# Installs a LaunchAgent that runs rkplex-deploy.sh every hour, and at once when the deploy repository
# (~/rkplex-deploy.git) receives a push. Most runs only check the branch and exit; a build happens
# on a new commit or before the profile lapses. The branch is pushed to that repository and tracks it,
# so from another machine on the tailnet: git push ssh://<user>@<mac>/~/rkplex-deploy.git <branch>
#
# Usage: install-launch-agent.sh <devicectl device id> <xcodebuild device udid> [branch]
#        install-launch-agent.sh --uninstall

set -euo pipefail

LABEL="com.rkplex.deploy"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
LOG_DIR="$HOME/Library/Logs/RKPlexDeploy"
SCRIPT="${0:A:h}/rkplex-deploy.sh"
REPO="${0:A:h:h:h}"
DEPLOY_REPO="$HOME/rkplex-deploy.git"
REQUESTS="$HOME/Library/Caches/RKPlexDeploy/requests"

if [[ ${1:-} == --uninstall ]]; then
    launchctl bootout "gui/$UID/$LABEL" 2>/dev/null || true
    rm -f "$PLIST"
    print "Removed $LABEL"
    exit 0
fi

device=${1:?devicectl device id, from: xcrun devicectl list devices}
destination=${2:?xcodebuild device UDID, from: xcrun xctrace list devices}
branch=${3:-$(git -C "$REPO" branch --show-current)}

mkdir -p "$LOG_DIR" "${PLIST:h}" "$REQUESTS"
chmod +x "$SCRIPT"

[[ -d $DEPLOY_REPO ]] || git init --quiet --bare "$DEPLOY_REPO"
install -m 755 "${0:A:h}/post-receive" "$DEPLOY_REPO/hooks/post-receive"

cat >"$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/zsh</string>
        <string>$SCRIPT</string>
    </array>
    <key>EnvironmentVariables</key>
    <dict>
        <key>RKPLEX_BRANCH</key>
        <string>$branch</string>
        <key>RKPLEX_DEVICE</key>
        <string>$device</string>
        <key>RKPLEX_DESTINATION</key>
        <string>$destination</string>
    </dict>
    <key>StartInterval</key>
    <integer>3600</integer>
    <key>WatchPaths</key>
    <array>
        <string>$REQUESTS</string>
    </array>
    <key>ProcessType</key>
    <string>Background</string>
    <key>StandardOutPath</key>
    <string>$LOG_DIR/deploy.log</string>
    <key>StandardErrorPath</key>
    <string>$LOG_DIR/deploy.log</string>
</dict>
</plist>
EOF

launchctl bootout "gui/$UID/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$UID" "$PLIST"

git -C "$REPO" remote get-url tv >/dev/null 2>&1 || git -C "$REPO" remote add tv "$DEPLOY_REPO"
git -C "$REPO" push --quiet --set-upstream tv "$branch"

print "Installed $LABEL: deploys $branch from $DEPLOY_REPO on push and checks hourly, log at $LOG_DIR/deploy.log"
