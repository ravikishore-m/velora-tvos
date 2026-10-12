//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

/// Video, audio and accessibility format badges as Velora glass pills
struct CinemaFormatBadges: View {

    enum Badge: Hashable {
        case uhd
        case hd
        case dolbyVision
        case hdr(String)
        case dolbyAtmos
        case dolbyDigital
        case audioFormat(String)
        case surround(String)
        case closedCaptions
        case sdh
        case audioDescription
    }

    struct Content: OptionSet {

        let rawValue: Int

        static let video = Content(rawValue: 1 << 0)
        static let audioFormat = Content(rawValue: 1 << 1)
        static let channels = Content(rawValue: 1 << 2)
        static let accessibility = Content(rawValue: 1 << 3)
        /// Channel layout only when no audio format badge is shown
        static let channelsFallback = Content(rawValue: 1 << 4)

        static let audio: Content = [.audioFormat, .channels]
        static let all: Content = [.video, .audio, .accessibility]
        /// The details page line
        static let summary: Content = [.video, .audioFormat, .channelsFallback, .accessibility]
    }

    /// Streams describing what plays: the video and the audio track(s) to badge
    let streams: [MediaStream]
    /// Every stream of the media source, used for caption and audio description availability
    var availableStreams: [MediaStream]?
    var content: Content = .all

    private var videoStream: MediaStream? {
        streams.first { $0.type == .video }
    }

    private var primaryAudioStream: MediaStream? {
        let audioStreams = streams.filter { $0.type == .audio }
        return audioStreams.first { $0.isDefault == true } ?? audioStreams.first
    }

    private var accessibilityStreams: [MediaStream] {
        availableStreams ?? streams
    }

    private static func text(of stream: MediaStream) -> [String] {
        [stream.profile, stream.displayTitle, stream.title].compactMap(\.self)
    }

    private var hasAtmos: Bool {
        streams.contains { stream in
            stream.type == .audio && Self.text(of: stream).contains { $0.localizedCaseInsensitiveContains("atmos") }
        }
    }

    /// Non-Dolby lossless and surround formats worth calling out
    private var audioFormatTitle: String? {
        guard let stream = primaryAudioStream, let codec = stream.codec?.lowercased() else { return nil }

        switch codec {
        case "dts", "dca":
            let profile = Self.text(of: stream).joined(separator: " ")
            if profile.localizedCaseInsensitiveContains("DTS:X") || profile.localizedCaseInsensitiveContains("DTS-X") {
                return L10n.dtsX
            }
            if profile.localizedCaseInsensitiveContains("MA") || profile.localizedCaseInsensitiveContains("HD") {
                return L10n.dtsHD
            }
            return L10n.dts

        case "truehd", "mlp":
            return L10n.trueHD

        default:
            return nil
        }
    }

    private var isDolbyDigital: Bool {
        guard let codec = primaryAudioStream?.codec?.lowercased() else { return false }

        return codec == "ac3" || codec == "eac3"
    }

    private var hasSDH: Bool {
        accessibilityStreams.hasSDHSubtitles
    }

    private var hasClosedCaptions: Bool {
        accessibilityStreams.hasClosedCaptions
    }

    private var hasAudioDescription: Bool {
        accessibilityStreams.hasAudioDescription
    }

    private var hdrTitle: String {
        switch videoStream?.videoRangeType {
        case .hdr10Plus, .doviWithHDR10Plus, .doviWithELHDR10Plus: L10n.hdr10Plus
        case .hdr10, .doviWithHDR10, .doviWithEL: L10n.hdr10
        case .hlg, .doviWithHLG: L10n.hlg
        default: L10n.hdr
        }
    }

    private var badges: [Badge] {
        var badges: [Badge] = []

        if content.contains(.video) {
            if streams.has4KVideo {
                badges.append(.uhd)
            } else if streams.hasHDVideo {
                badges.append(.hd)
            }

            if streams.hasDolbyVision {
                badges.append(.dolbyVision)
            } else if streams.hasHDRVideo {
                badges.append(.hdr(hdrTitle))
            }
        }

        var hasAudioFormatBadge = false

        if content.contains(.audioFormat) {
            hasAudioFormatBadge = true

            if hasAtmos {
                badges.append(.dolbyAtmos)
            } else if isDolbyDigital {
                badges.append(.dolbyDigital)
            } else if let audioFormatTitle {
                badges.append(.audioFormat(audioFormatTitle))
            } else {
                hasAudioFormatBadge = false
            }
        }

        if content.contains(.channels) || (content.contains(.channelsFallback) && !hasAudioFormatBadge) {
            if streams.has71AudioChannelLayout {
                badges.append(.surround(L10n.surround71))
            } else if streams.has51AudioChannelLayout {
                badges.append(.surround(L10n.surround51))
            }
        }

        if content.contains(.accessibility) {
            if hasClosedCaptions {
                badges.append(.closedCaptions)
            }
            if hasSDH {
                badges.append(.sdh)
            }
            if hasAudioDescription {
                badges.append(.audioDescription)
            }
        }

        return badges
    }

    var body: some View {
        HStack(spacing: CinemaTheme.Badge.spacing) {
            ForEach(badges, id: \.self) { badge in
                BadgeView(badge: badge)
            }
        }
        .fixedSize()
        .accessibilityElement(children: .combine)
    }
}

extension [MediaStream] {

    private static func text(of stream: MediaStream) -> [String] {
        [stream.profile, stream.displayTitle, stream.title].compactMap(\.self)
    }

    private static func isSDH(_ stream: MediaStream) -> Bool {
        stream.isHearingImpaired == true || text(of: stream).contains { $0.contains("SDH") }
    }

    var hasSDHSubtitles: Bool {
        contains { $0.type == .subtitle && Self.isSDH($0) }
    }

    var hasClosedCaptions: Bool {
        contains { $0.type == .subtitle && $0.isForced != true && !Self.isSDH($0) }
    }

    var hasAudioDescription: Bool {
        contains { stream in
            guard stream.type == .audio else { return false }

            return Self.text(of: stream).contains { text in
                text.localizedCaseInsensitiveContains("descri")
                    || text.range(of: #"(^|[^A-Za-z])AD([^A-Za-z]|$)"#, options: .regularExpression) != nil
            }
        }
    }
}

extension CinemaFormatBadges {

    struct BadgeView: View {

        let badge: Badge

        /// A glass pill with a Velora glyph and the format's name
        private func pill(_ glyph: VeloraFormatGlyph, _ title: String) -> some View {
            HStack(spacing: CinemaTheme.Badge.iconSpacing) {
                VeloraFormatGlyphView(glyph: glyph)

                Text(title)
                    .font(.system(size: CinemaTheme.Badge.fontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(CinemaTheme.Badge.tint)
            }
            .padding(.horizontal, CinemaTheme.Badge.horizontalPadding)
            .frame(height: CinemaTheme.Badge.height)
            .glassEffect(.regular, in: Capsule())
            .lineLimit(1)
            .accessibilityElement()
            .accessibilityLabel(title)
        }

        private func logo(_ resource: ImageResource, title: String, height: CGFloat) -> some View {
            Image(resource)
                .renderingMode(.template)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(height: height)
                .foregroundStyle(CinemaTheme.Badge.tint)
                .accessibilityLabel(title)
        }

        /// Accessibility features read as plain outlined glass, apart from the picture and sound formats
        private func outline(_ title: String, accessibilityLabel: String) -> some View {
            Text(title)
                .font(.system(size: CinemaTheme.Badge.fontSize, weight: .bold, design: .rounded))
                .foregroundStyle(CinemaTheme.Badge.tint)
                .padding(.horizontal, CinemaTheme.Badge.horizontalPadding)
                .frame(height: CinemaTheme.Badge.height)
                .glassEffect(.regular, in: Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(CinemaTheme.Colors.secondaryText, lineWidth: CinemaTheme.Badge.outlineWidth)
                }
                .lineLimit(1)
                .accessibilityElement()
                .accessibilityLabel(accessibilityLabel)
        }

        var body: some View {
            switch badge {
            case .uhd:
                pill(.resolution, L10n.fourK)
            case .hd:
                pill(.resolution, L10n.hd)
            case .dolbyVision:
                logo(.dolbyVision, title: L10n.dolbyVision, height: CinemaTheme.Badge.stackedLogoHeight)
            case let .hdr(title):
                pill(.range, title)
            case .dolbyAtmos:
                logo(.dolbyAtmos, title: L10n.dolbyAtmos, height: CinemaTheme.Badge.stackedLogoHeight)
            case .dolbyDigital:
                logo(.dolbyDigital, title: L10n.dolbyDigital, height: CinemaTheme.Badge.wideLogoHeight)
            case let .audioFormat(title):
                pill(title == L10n.dtsX ? .spatial : .sound, title)
            case let .surround(title):
                pill(.channels, title)
            case .closedCaptions:
                outline(L10n.cc, accessibilityLabel: L10n.closedCaptions)
            case .sdh:
                outline(L10n.sdh, accessibilityLabel: L10n.sdhSubtitles)
            case .audioDescription:
                outline(L10n.ad, accessibilityLabel: L10n.audioDescription)
            }
        }
    }
}
