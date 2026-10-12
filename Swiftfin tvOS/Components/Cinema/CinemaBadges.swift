//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

/// Apple TV app style metadata line: "2024 · 46m  14+  4K  Dolby Vision  Dolby Atmos  CC  SDH  AD"
struct CinemaBadges: View {

    let item: BaseItemDto
    /// Streams of the selected version, falling back to the item's own streams
    var mediaStreams: [MediaStream]?
    var formats: CinemaFormatBadges.Content = [.video, .audioFormat]
    var showsRatings: Bool = false

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
                Text(runtime, format: .hourMinuteAbbreviated)
            } else if let firstGenre = item.genres?.first {
                Text(firstGenre)
            }

            if let seasonEpisodeLabel = item.seasonEpisodeLabel {
                Text(seasonEpisodeLabel)
            }
        }
    }

    @ViewBuilder
    private var ratings: some View {
        if let criticRating = item.criticRating {
            HStack(spacing: CinemaTheme.Badge.iconSpacing) {
                Image(criticRating >= 60 ? .tomatoFresh : .tomatoRotten)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(CinemaTheme.Colors.accent)

                Text(Double(criticRating) / 100, format: .percent.precision(.fractionLength(0)))
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(L10n.criticRating)
        }

        if let communityRating = item.communityRating {
            HStack(spacing: CinemaTheme.Badge.iconSpacing) {
                Image(systemName: "star.fill")
                    .foregroundStyle(CinemaTheme.Badge.star)

                Text(Double(communityRating), format: .number.precision(.fractionLength(1)))
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(L10n.communityRating)
        }
    }

    var body: some View {
        HStack(spacing: CinemaTheme.Badge.groupSpacing) {
            facts

            if showsRatings {
                ratings
            }

            if let officialRating = item.officialRating {
                Text(officialRating)
            }

            if streams.isNotEmpty {
                CinemaFormatBadges(
                    streams: streams,
                    content: formats
                )
            }
        }
        .font(CinemaTheme.Typography.metadata)
        .foregroundStyle(CinemaTheme.Colors.secondaryText)
        .lineLimit(1)
        .fixedSize(horizontal: false, vertical: true)
    }
}
