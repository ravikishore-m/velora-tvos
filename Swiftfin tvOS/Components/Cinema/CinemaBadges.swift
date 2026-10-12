//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

/// "Movie · Action · Drama", the line above the synopsis
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

/// Plain summary line for posters and the home hero: "Movie · Romance · 2026 · 2h 26m · A"
struct CinemaFactsLine: View {

    let item: BaseItemDto

    private var facts: [String] {
        [
            item.type == .episode ? item.seasonEpisodeLabel : item.type?.displayTitle,
            item.genres?.first,
            item.premiereDateYear,
            item.runtime.map(BaseItemDto.compactRuntime),
            item.officialRating,
        ]
            .compactMap(\.self)
            .filter(\.isNotEmpty)
    }

    var body: some View {
        if facts.isNotEmpty {
            Text(facts.joined(separator: " · "))
                .font(CinemaTheme.Typography.metadata)
                .foregroundStyle(CinemaTheme.Colors.primaryText.opacity(0.9))
                .lineLimit(1)
        }
    }
}

extension BaseItemDto {

    /// "2h 6m" and "46m", rather than the locale's "2 hrs, 6 min"
    static func compactRuntime(_ runtime: Duration) -> String {
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
}

/// Details metadata line: "2024 · 46m", the rating, then the format pills
struct CinemaBadges: View {

    let item: BaseItemDto
    /// Streams of the selected version, falling back to the item's own streams
    var mediaStreams: [MediaStream]?
    var formats: CinemaFormatBadges.Content = [.video, .audioFormat]

    private var streams: [MediaStream] {
        mediaStreams ?? item.mediaStreams ?? []
    }

    @ViewBuilder
    private var facts: some View {
        DotHStack {
            if let premiereYear = item.premiereDateYear {
                Text(premiereYear)
            }

            if let runtime = item.runtime {
                Text(BaseItemDto.compactRuntime(runtime))
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
            Text(officialRating)
                .font(.system(size: CinemaTheme.Badge.fontSize, weight: .bold, design: .rounded))
                .foregroundStyle(CinemaTheme.Colors.primaryText)
                .padding(.horizontal, CinemaTheme.Badge.horizontalPadding)
                .frame(height: CinemaTheme.Badge.height)
                .glassEffect(.regular.tint(CinemaTheme.Colors.accent.opacity(0.35)), in: Capsule())
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
        .fixedSize(horizontal: true, vertical: true)
    }
}
