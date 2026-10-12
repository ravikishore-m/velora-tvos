//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import MPVUI
import SwiftUI

/// Live playback readout. Numbers come from the hardware player and the file Jellyfin opened.
struct CinemaPlaybackStats: View {

    private struct Reading {
        var networkMbps: Double = 0
        var bufferFill: Double = 0
        var decodeFPS: Double?
        var videoRows: [Stat] = []
        var audioRows: [Stat] = []
        var streamRows: [Stat] = []
        var decodeRows: [Stat] = []
    }

    private struct Stat: Identifiable {
        var id: String {
            label
        }

        let label: String
        let value: String
    }

    private static let live = Color(red: 0.35, green: 0.95, blue: 0.5)
    private static let historyLimit = 42

    @EnvironmentObject
    private var manager: MediaPlayerManager

    @State
    private var reading = Reading()
    @State
    private var networkSamples: [Double] = []
    @State
    private var bufferSamples: [Double] = []
    @State
    private var decodeSamples: [Double] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                gauge(
                    L10n.network,
                    value: "\(Self.decimal(reading.networkMbps, places: 1)) Mbps",
                    samples: networkSamples,
                    range: networkRange
                )
                gauge(
                    L10n.buffer,
                    value: "\(Int((reading.bufferFill * 100).rounded()))%",
                    samples: bufferSamples,
                    range: 0 ... 1
                )
                gauge(
                    L10n.decode,
                    value: rateText(reading.decodeFPS),
                    samples: decodeSamples,
                    range: decodeRange
                )
            }

            HStack(alignment: .top, spacing: 32) {
                VStack(alignment: .leading, spacing: 18) {
                    section(L10n.video, rows: reading.videoRows)
                    section(L10n.decode, rows: reading.decodeRows)
                }
                VStack(alignment: .leading, spacing: 18) {
                    section(L10n.audio, rows: reading.audioRows)
                    section(L10n.stream, rows: reading.streamRows)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: 1280)
        .background {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.black.opacity(0.68))
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
        }
        .onAppear(perform: capture)
        .task(id: manager.playbackItem?.url) {
            networkSamples = []
            bufferSamples = []
            decodeSamples = []
            while !Task.isCancelled {
                capture()
                try? await Task.sleep(for: .milliseconds(500))
            }
        }
    }

    private var networkRange: ClosedRange<Double> {
        let low = networkSamples.min() ?? 0
        let high = max(networkSamples.max() ?? 1, low + 1)
        let pad = max(2, (high - low) * 0.35)
        return max(0, low - pad) ... (high + pad)
    }

    private var decodeRange: ClosedRange<Double> {
        let low = decodeSamples.min() ?? 0
        let high = max(decodeSamples.max() ?? 1, low + 0.5)
        let pad = max(0.4, (high - low) * 0.35)
        return max(0, low - pad) ... (high + pad)
    }

    private func gauge(
        _ title: String,
        value: String,
        samples: [Double],
        range: ClosedRange<Double>
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Self.live)
                .textCase(.uppercase)
            Text(value)
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(.white)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Sparkline(values: samples, range: range, color: Self.live)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func section(_ title: String, rows: [Stat]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Self.live)
                .textCase(.uppercase)
            ForEach(rows) { stat in
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(stat.label)
                        .foregroundStyle(CinemaTheme.Colors.secondaryText)
                        .frame(width: 150, alignment: .leading)
                    Text(stat.value)
                        .foregroundStyle(.white)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer(minLength: 0)
                }
                .font(.system(size: 22, weight: .medium))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func capture() {
        let item = manager.playbackItem
        let video = item?.videoStreams.first
        let audio = selectedAudio(in: item)
        let player = (manager.proxy as? MPVMediaPlayerProxy)?.player
        let diagnostics = player?.playbackDiagnostics
        let buffer = player?.bufferStatus
        let media = player?.mediaInformation

        let mbps = Double(buffer?.inputRate ?? 0) * 8 / 1_000_000
        let cache = max(player?.configuration.networkCacheSeconds.seconds ?? 4, 0.1)
        let ahead = buffer?.secondsBufferedAhead.seconds ?? 0
        let fill = min(1, ahead / cache)
        let decode = decodeRate(diagnostics: diagnostics, mediaFPS: media?.framesPerSecond, video: video)

        networkSamples = push(mbps, into: networkSamples)
        bufferSamples = push(fill, into: bufferSamples)
        decodeSamples = push(decode ?? 0, into: decodeSamples)

        let fileFPS = fileFrameRate(video: video, mediaFPS: media?.framesPerSecond)
        reading = Reading(
            networkMbps: mbps,
            bufferFill: fill,
            decodeFPS: decode,
            videoRows: [
                Stat(label: L10n.codec, value: codecTitle(media?.videoCodec ?? video?.codec)),
                Stat(label: L10n.resolution, value: resolution(media: media, video: video)),
                Stat(label: L10n.fps, value: fileFPS.map { Self.decimal($0, places: 2) } ?? .emptyDash),
                Stat(label: L10n.format, value: formatTitle(diagnostics: diagnostics, bitDepth: video?.bitDepth)),
                Stat(label: L10n.videoRange, value: rangeTitle(video)),
            ],
            audioRows: [
                Stat(label: L10n.codec, value: codecTitle(diagnostics?.audio.codec ?? audio?.codec)),
                Stat(label: L10n.layout, value: layoutTitle(diagnostics: diagnostics, stream: audio)),
                Stat(label: L10n.rate, value: sampleRateTitle(audio?.sampleRate)),
            ],
            streamRows: [
                Stat(label: L10n.server, value: manager.userSession?.server.name ?? .emptyDash),
                Stat(label: L10n.method, value: methodTitle(item)),
                Stat(label: L10n.container, value: containerTitle(media?.container ?? item?.mediaSource.container)),
                Stat(label: L10n.source, value: item?.url.isFileURL == true ? L10n.file : L10n.network),
                Stat(label: L10n.bitrate, value: bitrateTitle(item?.mediaSource.bitrate)),
            ],
            decodeRows: [
                Stat(label: L10n.pipeline, value: L10n.playbackPipeline),
                Stat(label: L10n.hw, value: hardwareTitle(diagnostics)),
                Stat(label: L10n.rate, value: rateText(decode)),
                Stat(label: L10n.frames, value: frameCount(diagnostics)),
                Stat(label: L10n.audioVideo, value: offsetTitle(diagnostics?.audioVideoDriftSeconds)),
            ]
        )
    }

    private func selectedAudio(in item: MediaPlayerItem?) -> MediaStream? {
        guard let item else { return nil }

        if let index = item.selectedAudioStreamIndex {
            return item.audioStreams.first { $0.index == index }
        }
        return item.audioStreams.first
    }

    private func decodeRate(
        diagnostics: MPVPlaybackDiagnostics?,
        mediaFPS: Double?,
        video: MediaStream?
    ) -> Double? {
        if let value = diagnostics?.estimatedDecodedFramesPerSecond, value > 0 {
            return value
        }
        if let value = diagnostics?.estimatedFilterFramesPerSecond, value > 0 {
            return value
        }
        return fileFrameRate(video: video, mediaFPS: diagnostics?.containerFramesPerSecond ?? mediaFPS)
    }

    private func fileFrameRate(video: MediaStream?, mediaFPS: Double?) -> Double? {
        if let value = video?.realFrameRate ?? video?.averageFrameRate, value > 0 {
            return Double(value)
        }
        if let mediaFPS, mediaFPS > 0 {
            return mediaFPS
        }
        return nil
    }

    private func resolution(media: MPVMediaInformation?, video: MediaStream?) -> String {
        if let dimensions = media?.dimensions, dimensions.effectiveWidth > 0, dimensions.effectiveHeight > 0 {
            return "\(dimensions.effectiveWidth)x\(dimensions.effectiveHeight)"
        }
        if let width = video?.width, let height = video?.height {
            return "\(width)x\(height)"
        }
        return .emptyDash
    }

    private func formatTitle(diagnostics: MPVPlaybackDiagnostics?, bitDepth: Int?) -> String {
        let decoder: String
        switch diagnostics?.decoder.session {
        case let .hardware(name):
            let lowered = name.lowercased()
            decoder = lowered.isEmpty || lowered.contains("videotoolbox") ? "videotoolbox" : lowered

        case .software:
            decoder = "software"

        case .unknown, nil:
            decoder = diagnostics?.decoder.selectedDecoder?.lowercased() ?? ""
        }

        guard !decoder.isEmpty else { return .emptyDash }

        if let bitDepth {
            return "\(decoder) \(bitDepth)-bit"
        }
        return decoder
    }

    private func rangeTitle(_ video: MediaStream?) -> String {
        guard let range = video?.videoRangeType, range != .unknown else { return .emptyDash }

        return range.displayTitle
    }

    private func layoutTitle(diagnostics: MPVPlaybackDiagnostics?, stream: MediaStream?) -> String {
        if let raw = diagnostics?.audio.sourceChannels ?? stream?.channelLayout, !raw.isEmpty {
            let cleaned = raw
                .replacing("(side)", with: "")
                .replacing("(wide)", with: "")
                .trimmingCharacters(in: .whitespaces)
            switch cleaned.lowercased() {
            case "stereo", "2", "2.0":
                return "Stereo"
            case "mono", "1", "1.0":
                return "Mono"
            default:
                if cleaned.contains(".") {
                    return "\(cleaned) Surround"
                }
                return cleaned
            }
        }
        return channelCountTitle(stream?.channels)
    }

    private func channelCountTitle(_ channels: Int?) -> String {
        switch channels {
        case 8:
            "7.1 Surround"
        case 6:
            "5.1 Surround"
        case 2:
            "Stereo"
        case 1:
            "Mono"
        case let count?:
            "\(count)"
        default:
            .emptyDash
        }
    }

    private func sampleRateTitle(_ sampleRate: Int?) -> String {
        guard let sampleRate, sampleRate > 0 else { return .emptyDash }

        return "\(sampleRate) Hz"
    }

    private func methodTitle(_ item: MediaPlayerItem?) -> String {
        guard let item else { return .emptyDash }

        return item.mediaSource.transcodingURL == nil ? L10n.directPlay : L10n.transcode
    }

    private func bitrateTitle(_ bitrate: Int?) -> String {
        guard let bitrate, bitrate > 0 else { return .emptyDash }

        return "\(bitrate / 1000) kbps"
    }

    private func hardwareTitle(_ diagnostics: MPVPlaybackDiagnostics?) -> String {
        switch diagnostics?.decoder.session {
        case .hardware:
            "VideoToolbox"
        case .software:
            "Software"
        case .unknown, nil:
            diagnostics?.decoder.videoToolboxSessionUsesHardware == true ? "VideoToolbox" : .emptyDash
        }
    }

    private func frameCount(_ diagnostics: MPVPlaybackDiagnostics?) -> String {
        guard let count = diagnostics?.nativeOutputStatistics?.sampleBuildCount else { return .emptyDash }

        return "\(count)"
    }

    private func offsetTitle(_ seconds: Double?) -> String {
        guard let seconds else { return .emptyDash }

        let milliseconds = Int((seconds * 1000).rounded())
        if milliseconds > 0 {
            return "+\(milliseconds) ms"
        }
        return "\(milliseconds) ms"
    }

    private func rateText(_ fps: Double?) -> String {
        guard let fps, fps > 0 else { return .emptyDash }

        return "\(Self.decimal(fps, places: 1)) fps"
    }

    private func codecTitle(_ raw: String?) -> String {
        guard let raw = raw?.lowercased(), !raw.isEmpty else { return .emptyDash }

        switch raw {
        case "truehd":
            return "TrueHD"
        case "eac3":
            return "E-AC-3"
        case "ac3":
            return "AC-3"
        case "dts":
            return "DTS"
        case "dtshd", "dts-hd":
            return "DTS-HD"
        case "flac":
            return "FLAC"
        case "aac":
            return "AAC"
        case "opus":
            return "Opus"
        case "hevc", "h265":
            return "hevc"
        case "h264", "avc":
            return "h264"
        default:
            return raw
        }
    }

    private func containerTitle(_ raw: String?) -> String {
        guard let raw, !raw.isEmpty else { return .emptyDash }

        let tokens = raw.lowercased().split { $0 == "," || $0 == "/" }.map {
            $0.trimmingCharacters(in: .whitespaces)
        }
        var names: [String] = []
        for token in tokens where !token.isEmpty {
            let name = switch token {
            case "mkv", "matroska":
                "Matroska"
            case "webm":
                "WebM"
            case "mp4":
                "MP4"
            case "mov":
                "MOV"
            case "m4v":
                "M4V"
            case "ts", "mpegts":
                "MPEG-TS"
            default:
                token
            }
            if !names.contains(name) {
                names.append(name)
            }
        }
        return names.isEmpty ? .emptyDash : names.joined(separator: " / ")
    }

    private func push(_ value: Double, into samples: [Double]) -> [Double] {
        var samples = samples
        if samples.isEmpty {
            samples = [value, value]
        } else {
            samples.append(value)
        }
        if samples.count > Self.historyLimit {
            samples.removeFirst(samples.count - Self.historyLimit)
        }
        return samples
    }

    private static func decimal(_ value: Double, places: Int) -> String {
        String(format: "%.\(places)f", locale: Locale(identifier: "en_US_POSIX"), value)
    }
}

private struct Sparkline: View {

    var values: [Double]
    var range: ClosedRange<Double>
    var color: Color

    var body: some View {
        Canvas { context, size in
            guard values.count >= 2 else { return }

            let span = range.upperBound - range.lowerBound
            guard span > 0, size.width > 0, size.height > 0 else { return }

            var path = Path()
            for (index, value) in values.enumerated() {
                let x = size.width * Double(index) / Double(values.count - 1)
                let clamped = min(max(value, range.lowerBound), range.upperBound)
                let y = size.height * (1 - (clamped - range.lowerBound) / span)
                let point = CGPoint(x: x, y: y)
                if index == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
            context.stroke(
                path,
                with: .color(color),
                style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
            )
        }
        .frame(height: 30)
    }
}
