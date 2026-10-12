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

    private static let nonVideoReasons: Set<TranscodeReason> = [
        .containerNotSupported,
        .audioCodecNotSupported,
        .audioIsExternal,
        .secondaryAudioNotSupported,
        .audioChannelsNotSupported,
        .audioProfileNotSupported,
        .audioSampleRateNotSupported,
        .audioBitDepthNotSupported,
        .audioBitrateNotSupported,
        .unknownAudioStreamInfo,
    ]

    private static let audioReasons: Set<TranscodeReason> = nonVideoReasons.subtracting([.containerNotSupported])

    private var transcodingQuery: [URLQueryItem] {
        guard let url = playbackItem?.mediaSource.transcodingURL else { return [] }

        return URLComponents(string: url)?.queryItems ?? []
    }

    private func queryValue(_ name: String) -> String? {
        transcodingQuery.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }?.value
    }

    private var reasons: [TranscodeReason] {
        if let reasons = session?.transcodingInfo?.transcodeReasons, reasons.isNotEmpty {
            return reasons
        }

        return (queryValue("TranscodeReasons") ?? "")
            .split(separator: ",")
            .compactMap { TranscodeReason(rawValue: String($0)) }
    }

    /// Clients report a repackaged stream as a transcode, so prefer the server's per-stream details
    private var method: Method {
        if let transcodingInfo = session?.transcodingInfo,
           let isVideoDirect = transcodingInfo.isVideoDirect,
           let isAudioDirect = transcodingInfo.isAudioDirect
        {
            if isVideoDirect, isAudioDirect {
                return .remux
            } else if isVideoDirect {
                return .audioConverted
            }
            return .transcode
        }

        guard playbackItem?.mediaSource.transcodingURL != nil else {
            return session?.playState?.playMethod == .transcode ? .transcode : .directPlay
        }

        let reasons = Set(reasons)

        if reasons.isEmpty || !reasons.isSubset(of: Self.nonVideoReasons) {
            return .transcode
        } else if reasons.isDisjoint(with: Self.audioReasons) {
            return .remux
        }
        return .audioConverted
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

    private func codecTitle(_ codec: String?) -> String? {
        switch codec?.lowercased() {
        case "hevc", "h265": "HEVC"
        case "h264", "avc": "H.264"
        case "av1": "AV1"
        case "eac3": "Dolby Digital Plus"
        case "ac3": "Dolby Digital"
        case "truehd", "mlp": "TrueHD"
        case "dts", "dca": "DTS"
        case let .some(codec):
            codec.uppercased()
        case nil:
            nil
        }
    }

    /// Resolution, codec and bitrate. Skips release-group names that Jellyfin puts in `displayTitle`.
    private var videoDescription: String? {
        guard let videoStream else { return nil }

        let resolution: String? = if videoStream.is4kVideo {
            L10n.fourK
        } else if let height = videoStream.height, height > 0 {
            "\(height)p"
        } else {
            nil
        }

        let range = videoStream.videoRangeType?.displayTitle
        let parts = [
            resolution,
            codecTitle(videoStream.codec),
            range == L10n.sdr ? nil : range,
            videoStream.bitRate.map { $0.formatted(.bitRate) },
        ]
            .compactMap(\.self)

        if parts.isNotEmpty {
            return parts.joined(separator: " · ")
        }

        return videoStream.displayTitle
    }

    private var audioLanguage: String? {
        guard let code = audioStream?.language, code.isNotEmpty, code.lowercased() != "und" else { return nil }

        return Locale.current.localizedString(forLanguageCode: code) ?? code
    }

    private var audioFormat: String? {
        guard let audioStream else { return nil }

        let text = [audioStream.profile, audioStream.displayTitle, audioStream.title].compactMap(\.self)
        if text.contains(where: { $0.localizedCaseInsensitiveContains("atmos") }) {
            return L10n.dolbyAtmos
        }
        return codecTitle(audioStream.codec)
    }

    private var audioDescription: String? {
        guard audioStream != nil else { return nil }

        let source = [
            audioLanguage,
            audioFormat,
            audioStream?.channelLayout,
            audioStream?.bitRate.map { $0.formatted(.bitRate) },
        ]
            .compactMap(\.self)
            .joined(separator: " · ")

        guard source.isNotEmpty else { return audioStream?.displayTitle }
        guard method == .audioConverted || method == .transcode else { return source }

        let codec: String?
        let channelCount: Int?

        if let transcodingInfo = session?.transcodingInfo, transcodingInfo.isAudioDirect != true {
            codec = transcodingInfo.audioCodec
            channelCount = transcodingInfo.audioChannels
        } else {
            codec = queryValue("AudioCodec")?.split(separator: ",").first.map(String.init)
            let maxChannels = queryValue("TranscodingMaxAudioChannels").flatMap(Int.init)
            channelCount = [audioStream?.channels, maxChannels].compactMap(\.self).min()
        }

        guard let codec else { return source }

        let channels: String = switch channelCount {
        case 8: L10n.surround71
        case 6: L10n.surround51
        case let .some(count): "\(count)ch"
        case nil: ""
        }

        return "\(source) → \(codec.uppercased()) \(channels)".trimmingCharacters(in: .whitespaces)
    }

    private var transcodeReasons: String? {
        guard reasons.isNotEmpty else { return nil }

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
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
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
                    content: .summary
                )
            }

            Text(status.description)
                .font(.callout)
                .foregroundStyle(CinemaTheme.Colors.secondaryText)

            VStack(alignment: .leading, spacing: 12) {
                row(L10n.video, value: videoDescription)
                row(L10n.audio, value: audioDescription)
                row(L10n.videoPlayer, value: Defaults[.VideoPlayer.videoPlayerType].displayTitle)
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
