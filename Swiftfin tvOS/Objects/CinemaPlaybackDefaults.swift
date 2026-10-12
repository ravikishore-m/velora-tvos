//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults

enum CinemaPlaybackDefaults {

    /// Per user, so each profile is moved once and can still choose AVPlayer afterwards
    private static var directPlayerMigrated: Defaults.Key<Bool> {
        Defaults.Key("cinemaDirectPlayerMigrated", default: false, suite: .currentUserSuite)
    }

    /// AVPlayer cannot open MKV, PGS subtitles or TrueHD, so the server transcodes those titles
    /// and has to restart the transcode on every subtitle change. VLC plays them directly.
    static func preferDirectPlayer() {
        guard !Defaults[directPlayerMigrated] else { return }

        Defaults[directPlayerMigrated] = true

        if Defaults[.VideoPlayer.videoPlayerType] == .avPlayer {
            Defaults[.VideoPlayer.videoPlayerType] = .vlc
        }
    }
}
