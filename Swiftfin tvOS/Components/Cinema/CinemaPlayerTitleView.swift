//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

/// Player header showing only the title logo, plus the episode for series
struct CinemaPlayerTitleView: View {

    let item: BaseItemDto

    @ViewBuilder
    private var logo: some View {
        ImageView(
            item.cinemaLogoSource(
                maxWidth: CinemaTheme.Player.logoMaxWidth,
                maxHeight: CinemaTheme.Player.logoMaxHeight
            )
        )
        .image { (image: Image) in
            image
                .aspectRatio(contentMode: .fit)
        }
        .placeholder { _ in
            EmptyView()
        }
        .failure {
            Text(item.cinemaTitle)
                .font(.title2.weight(.bold))
                .lineLimit(1)
        }
        .frame(
            maxWidth: CinemaTheme.Player.logoMaxWidth,
            maxHeight: CinemaTheme.Player.logoMaxHeight,
            alignment: .bottomLeading
        )
        .accessibilityLabel(item.cinemaTitle)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            logo

            if item.type == .episode {
                DotHStack {
                    if let seasonEpisodeLabel = item.seasonEpisodeLabel {
                        Text(seasonEpisodeLabel)
                    }

                    Text(item.displayTitle)
                }
                .font(.callout.weight(.semibold))
                .lineLimit(1)
            }
        }
        .foregroundStyle(CinemaTheme.Colors.primaryText)
    }
}
