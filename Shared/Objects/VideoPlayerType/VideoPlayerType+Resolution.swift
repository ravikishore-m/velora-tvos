//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults

extension VideoPlayerType {

    /// The player for this session.
    ///
    /// On Apple TV that is the hardware player: it opens the original file, VideoToolbox
    /// decodes the picture, and Apple's audio output keeps the source channels, including
    /// Dolby Atmos carried in Dolby Digital Plus. AVPlayer cannot open MKV, so sending
    /// 4K there made Jellyfin repackage the movie.
    static func resolved() -> VideoPlayerType {
        #if os(tvOS)
        if Defaults[.VideoPlayer.videoPlayerType] != .mpv {
            Defaults[.VideoPlayer.videoPlayerType] = .mpv
        }
        return .mpv
        #else
        return Defaults[.VideoPlayer.videoPlayerType]
        #endif
    }
}
