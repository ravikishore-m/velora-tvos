//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI

extension VideoPlayerType {

    /// The player for a title: the chosen player, except that on Apple TV, VLC hands 4K and HDR video
    /// to AVPlayer, whose hardware path keeps up with it. VLC falls behind on 4K 10-bit HEVC,
    /// freezing the picture while the sound carries on.
    static func resolved(
        for mediaSource: MediaSourceInfo?,
        subtitleStreamIndex: Int? = nil
    ) -> VideoPlayerType {
        let chosen = Defaults[.VideoPlayer.videoPlayerType]

        #if os(tvOS)
        guard chosen == .vlc, let mediaSource else { return chosen }

        let streams = mediaSource.mediaStreams ?? []
        guard let video = streams.first(where: { $0.type == .video }) else { return chosen }

        let isUltraHD = (video.width ?? 0) > 2048 || (video.height ?? 0) > 1200
        let isHDR = video.videoRangeType.map { $0 != .sdr && $0 != .unknown } ?? false
        guard isUltraHD || isHDR else { return chosen }

        // AVPlayer has picture subtitles burned in, which re-encodes the whole video on the server
        let subtitleIndex = subtitleStreamIndex ?? mediaSource.defaultSubtitleStreamIndex
        if let subtitleIndex, subtitleIndex >= 0,
           let subtitle = streams.first(where: { $0.type == .subtitle && $0.index == subtitleIndex }),
           subtitle.isTextSubtitleStream != true
        {
            return chosen
        }

        return .avPlayer
        #else
        return chosen
        #endif
    }
}
