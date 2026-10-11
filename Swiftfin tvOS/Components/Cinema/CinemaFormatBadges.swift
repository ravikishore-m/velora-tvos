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
        case surround(String)
    }

    let streams: [MediaStream]
    var includesAudio: Bool = true

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

        guard includesAudio else { return badges }

        if hasAtmos {
            badges.append(.dolbyAtmos)
        }

        if streams.has71AudioChannelLayout {
            badges.append(.surround(L10n.surround71))
        } else if streams.has51AudioChannelLayout {
            badges.append(.surround(L10n.surround51))
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

        /// "Dolby" in a light weight followed by the product name in heavy small caps
        private func dolby(_ title: String) -> some View {
            let parts = title.split(separator: " ", maxSplits: 1).map(String.init)

            return HStack(spacing: 6) {
                Text(parts.first ?? title)
                    .fontWeight(.medium)

                if let product = parts.last, parts.count > 1 {
                    Text(product.uppercased())
                        .fontWeight(.black)
                        .tracking(1.5)
                }
            }
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

            case .dolbyVision:
                dolby(L10n.dolbyVision)

            case let .hdr(title):
                Text(title)
                    .fontWeight(.heavy)

            case .dolbyAtmos:
                dolby(L10n.dolbyAtmos)

            case let .surround(title):
                Label(title, systemImage: "hifispeaker.2.fill")
                    .labelStyle(.titleAndIcon)
                    .fontWeight(.heavy)
            }
        }

        private var isFilled: Bool {
            badge == .uhd
        }

        var body: some View {
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
