//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

/// Plain-language summary of how the current item is being played
struct CinemaPlaybackSummary: View {

    let session: SessionInfoDto?
    let playbackItem: MediaPlayerItem?
    let videoStream: MediaStream?
    let audioStream: MediaStream?

    private enum Method {
        case directPlay
        case remux
        case audioConverted
        case transcode
    }

    /// Clients report a repackaged stream as a transcode, so prefer the server's per-stream details
    private var method: Method {
        if let transcodingInfo = session?.transcodingInfo {
            let isVideoDirect = transcodingInfo.isVideoDirect ?? false
            let isAudioDirect = transcodingInfo.isAudioDirect ?? false

            if isVideoDirect, isAudioDirect {
                return .remux
            } else if isVideoDirect {
                return .audioConverted
            }
            return .transcode
        }

        switch session?.playState?.playMethod {
        case .directPlay:
            return .directPlay
        case .directStream:
            return .remux
        case .transcode:
            return .transcode
        case nil:
            return playbackItem?.mediaSource.transcodingURL == nil ? .directPlay : .transcode
        }
    }

    private var status: (title: String, description: String, systemImage: String, color: Color) {
        switch method {
        case .directPlay:
            (L10n.directPlay, L10n.directPlayDescription, "checkmark.circle.fill", .green)
        case .remux:
            (L10n.remux, L10n.remuxDescription, "checkmark.circle.fill", .green)
        case .audioConverted:
            (L10n.audioConverted, L10n.audioConvertedDescription, "speaker.wave.2.circle.fill", .yellow)
        case .transcode:
            (L10n.transcode, L10n.transcodeDescription, "exclamationmark.triangle.fill", CinemaTheme.Player.warning)
        }
    }

    private var videoDescription: String? {
        guard let videoStream else { return nil }

        return [
            videoStream.displayTitle,
            videoStream.bitRate.map { $0.formatted(.bitRate) },
        ]
            .compactMap(\.self)
            .joined(separator: " · ")
    }

    private var audioDescription: String? {
        guard let source = audioStream?.displayTitle else { return nil }
        guard let transcodingInfo = session?.transcodingInfo,
              transcodingInfo.isAudioDirect != true,
              let codec = transcodingInfo.audioCodec
        else { return source }

        let channels: String = switch transcodingInfo.audioChannels {
        case 8: L10n.surround71
        case 6: L10n.surround51
        case let .some(count): "\(count)ch"
        case nil: ""
        }

        return "\(source) → \(codec.uppercased()) \(channels)".trimmingCharacters(in: .whitespaces)
    }

    private var transcodeReasons: String? {
        guard let reasons = session?.transcodingInfo?.transcodeReasons, reasons.isNotEmpty else { return nil }

        return reasons.map(\.displayTitle).joined(separator: ", ")
    }

    @ViewBuilder
    private func row(_ title: String, value: String?) -> some View {
        if let value, value.isNotEmpty {
            HStack(alignment: .firstTextBaseline, spacing: 24) {
                Text(title)
                    .foregroundStyle(CinemaTheme.Colors.tertiaryText)
                    .frame(width: 220, alignment: .leading)

                Text(value)
                    .foregroundStyle(CinemaTheme.Colors.primaryText)
                    .lineLimit(2)
            }
        }
    }

    var body: some View {
        let status = status

        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 20) {
                Label(status.title, systemImage: status.systemImage)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(status.color)

                CinemaFormatBadges(
                    streams: [videoStream, audioStream].compactMap(\.self),
                    availableStreams: playbackItem.map { $0.audioStreams + $0.subtitleStreams },
                    content: .all
                )
            }

            Text(status.description)
                .font(.callout)
                .foregroundStyle(CinemaTheme.Colors.secondaryText)

            VStack(alignment: .leading, spacing: 12) {
                row(L10n.video, value: videoDescription)
                row(L10n.audio, value: audioDescription)
                row(L10n.videoPlayer, value: VideoPlayerType.current.displayTitle)
                row(L10n.container, value: playbackItem?.mediaSource.container?.uppercased())
                row(L10n.transcodeReasons, value: transcodeReasons)
            }
            .font(.callout)
        }
        .padding(36)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 32))
        .environment(\.colorScheme, .dark)
    }
}
