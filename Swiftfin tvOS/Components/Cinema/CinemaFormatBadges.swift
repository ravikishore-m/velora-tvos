//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

/// Video and audio format badges in the style of the Apple TV app
struct CinemaFormatBadges: View {

    enum Badge: Hashable {
        case uhd
        case hd
        case dolbyVision
        case hdr(String)
        case dolbyAtmos
        case dolbyDigital
        case surround(String)
    }

    struct Content: OptionSet {

        let rawValue: Int

        static let video = Content(rawValue: 1 << 0)
        static let dolbyAudio = Content(rawValue: 1 << 1)
        static let channels = Content(rawValue: 1 << 2)

        static let audio: Content = [.dolbyAudio, .channels]
        static let all: Content = [.video, .audio]
    }

    let streams: [MediaStream]
    var content: Content = .all

    private var videoStream: MediaStream? {
        streams.first { $0.type == .video }
    }

    private var hasAtmos: Bool {
        streams.contains { stream in
            guard stream.type == .audio else { return false }

            return [stream.profile, stream.displayTitle, stream.title]
                .compactMap(\.self)
                .contains { $0.localizedCaseInsensitiveContains("atmos") }
        }
    }

    private var hasDolbyDigital: Bool {
        streams.contains { stream in
            guard stream.type == .audio, let codec = stream.codec?.lowercased() else { return false }

            return codec == "ac3" || codec == "eac3"
        }
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

        if content.contains(.dolbyAudio) {
            if hasAtmos {
                badges.append(.dolbyAtmos)
            } else if hasDolbyDigital {
                badges.append(.dolbyDigital)
            }
        }

        if content.contains(.channels) {
            if streams.has71AudioChannelLayout {
                badges.append(.surround(L10n.surround71))
            } else if streams.has51AudioChannelLayout {
                badges.append(.surround(L10n.surround51))
            }
        }

        return badges
    }

    var body: some View {
        HStack(spacing: 12) {
            ForEach(badges, id: \.self) { badge in
                BadgeView(badge: badge)
            }
        }
        .fixedSize()
        .accessibilityElement(children: .combine)
    }
}

extension CinemaFormatBadges {

    private struct BadgeView: View {

        let badge: Badge

        private var shape: RoundedRectangle {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
        }

        private func logo(_ resource: ImageResource, title: String, height: CGFloat) -> some View {
            Image(resource)
                .renderingMode(.template)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(height: height)
                .foregroundStyle(CinemaTheme.Colors.primaryText)
                .accessibilityLabel(title)
        }

        @ViewBuilder
        private var label: some View {
            switch badge {
            case .uhd:
                Text(L10n.fourK)
                    .fontWeight(.black)

            case .hd:
                Text(L10n.hd)
                    .fontWeight(.black)

            case let .hdr(title):
                Text(title)
                    .fontWeight(.heavy)

            case let .surround(title):
                Label(title, systemImage: "hifispeaker.2.fill")
                    .labelStyle(.titleAndIcon)
                    .fontWeight(.heavy)

            case .dolbyVision, .dolbyAtmos, .dolbyDigital:
                EmptyView()
            }
        }

        private var isFilled: Bool {
            badge == .uhd
        }

        var body: some View {
            switch badge {
            case .dolbyVision:
                logo(.dolbyVision, title: L10n.dolbyVision, height: 40)
            case .dolbyAtmos:
                logo(.dolbyAtmos, title: L10n.dolbyAtmos, height: 40)
            case .dolbyDigital:
                logo(.dolbyDigital, title: L10n.dolbyDigital, height: 30)
            default:
                boxed
            }
        }

        private var boxed: some View {
            label
                .font(.system(size: 20))
                .foregroundStyle(isFilled ? Color.black : CinemaTheme.Colors.primaryText)
                .padding(.horizontal, 10)
                .frame(height: 34)
                .background {
                    if isFilled {
                        shape.fill(CinemaTheme.Colors.primaryText)
                    } else {
                        shape
                            .fill(CinemaTheme.Colors.primaryText.opacity(0.08))
                            .strokeBorder(CinemaTheme.Colors.primaryText.opacity(0.85), lineWidth: 1.5)
                    }
                }
                .lineLimit(1)
        }
    }
}
