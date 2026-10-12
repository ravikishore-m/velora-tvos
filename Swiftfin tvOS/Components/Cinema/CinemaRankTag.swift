//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

/// A chart position in a glass tile on the artwork's corner
struct CinemaRankTag: View {

    let rank: Int

    var body: some View {
        Text(rank, format: .number)
            .font(.system(size: CinemaTheme.Rank.numberSize, weight: .heavy, design: .rounded))
            .monospacedDigit()
            .minimumScaleFactor(0.6)
            .foregroundStyle(CinemaTheme.Brand.diagonalGradient)
            .frame(width: CinemaTheme.Rank.tileSize, height: CinemaTheme.Rank.tileSize)
            .glassEffect(
                .regular,
                in: RoundedRectangle(cornerRadius: CinemaTheme.Rank.tileCornerRadius, style: .continuous)
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(rank, format: .number))
    }
}

/// Marks a charting title in rows other than its chart
struct CinemaTopTenBadge: View {

    @ObservedObject
    private var store = CinemaTopTenStore.shared

    let item: BaseItemDto

    var body: some View {
        if store.contains(item) {
            HStack(spacing: 6) {
                VeloraFormatGlyphView(glyph: .sound, size: CinemaTheme.Rank.badgeFontSize)

                Text(L10n.topTen)
                    .font(.system(size: CinemaTheme.Rank.badgeFontSize, weight: .heavy, design: .rounded))
                    .foregroundStyle(CinemaTheme.Colors.primaryText)
            }
            .padding(.horizontal, CinemaTheme.Rank.badgeHorizontalPadding)
            .frame(height: CinemaTheme.Rank.badgeHeight)
            .glassEffect(.regular, in: Capsule())
            .lineLimit(1)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(L10n.topTen)
        }
    }
}
