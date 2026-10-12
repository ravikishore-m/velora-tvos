//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

/// "Movie · Action · Drama", the line above the synopsis in the Apple TV app
struct CinemaContentLine: View {

    let item: BaseItemDto

    private var title: String? {
        var parts: [String] = []

        if let type = item.type?.displayTitle, type.isNotEmpty {
            parts.append(type)
        }

        if let genres = item.genres?.prefix(2) {
            parts.append(contentsOf: genres)
        }

        return parts.isEmpty ? nil : parts.joined(separator: "  ·  ")
    }

    var body: some View {
        if let title {
            Text(title)
                .font(CinemaTheme.Typography.metadata)
                .foregroundStyle(CinemaTheme.Colors.secondaryText)
                .lineLimit(1)
        }
    }
}

/// Apple TV app metadata line: "2024 · 46m    ✓ 14+    4K    Dolby Vision    Dolby Atmos    CC  SDH  AD"
struct CinemaBadges: View {

    let item: BaseItemDto
    /// Streams of the selected version, falling back to the item's own streams
    var mediaStreams: [MediaStream]?
    var formats: CinemaFormatBadges.Content = [.video, .audioFormat]
    /// Shrinks the row to the available width. Full-screen rows keep their natural size.
    var fitsContainer: Bool = false

    private var streams: [MediaStream] {
        mediaStreams ?? item.mediaStreams ?? []
    }

    /// "2h 6m" and "46m", rather than the locale's "2 hrs, 6 min"
    private func compactRuntime(_ runtime: Duration) -> String {
        let totalMinutes = max(Int(runtime.seconds.rounded() / 60), 0)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0, minutes > 0 {
            return "\(hours)h \(minutes)m"
        }
        if hours > 0 {
            return "\(hours)h"
        }
        return "\(minutes)m"
    }

    @ViewBuilder
    private var facts: some View {
        DotHStack {
            if let premiereYear = item.premiereDateYear {
                Text(premiereYear)
            }

            if let runtime = item.runtime {
                Text(compactRuntime(runtime))
            } else if let firstGenre = item.genres?.first {
                Text(firstGenre)
            }

            if let seasonEpisodeLabel = item.seasonEpisodeLabel {
                Text(seasonEpisodeLabel)
            }
        }
        .foregroundStyle(Color.white.opacity(0.92))
    }

    @ViewBuilder
    private var contentRating: some View {
        if let officialRating = item.officialRating, officialRating.isNotEmpty {
            HStack(spacing: CinemaTheme.Badge.iconSpacing) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: CinemaTheme.Badge.ratingSize, weight: .bold))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, CinemaTheme.Badge.rating)
                    .accessibilityHidden(true)

                Text(officialRating)
                    .foregroundStyle(CinemaTheme.Colors.primaryText)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(L10n.parentalRating)
            .accessibilityValue(officialRating)
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: CinemaTheme.Badge.groupSpacing) {
            facts

            contentRating

            if streams.isNotEmpty {
                CinemaFormatBadges(
                    streams: streams,
                    content: formats
                )
                .layoutPriority(1)
            }
        }
        .font(CinemaTheme.Typography.metadata)
        .lineLimit(1)
        .modifier(CinemaBadgeRowLayout(fitsContainer: fitsContainer))
    }
}

/// Keeps the Apple TV badge row at its natural size, or scales it down inside a card
private struct CinemaBadgeRowLayout: ViewModifier {

    let fitsContainer: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if fitsContainer {
            content
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            content
                .fixedSize(horizontal: true, vertical: true)
        }
    }
}
