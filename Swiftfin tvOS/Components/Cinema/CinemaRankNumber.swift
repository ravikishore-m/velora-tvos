//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI
import UIKit

/// A large outlined rank shown beside a Top 10 poster
struct CinemaRankNumber: View {

    private static let font = UIFont.systemFont(ofSize: CinemaTheme.TopTen.numberSize, weight: .black)

    /// Directions the outline copies are offset in, giving an even stroke around each digit
    private static let outlineOffsets: [CGSize] = stride(from: 0.0, to: 360.0, by: 30.0).map { degrees in
        let radians = degrees * .pi / 180
        return CGSize(
            width: cos(radians) * CinemaTheme.TopTen.outlineWidth,
            height: sin(radians) * CinemaTheme.TopTen.outlineWidth
        )
    }

    let rank: Int

    private var number: Text {
        Text(rank, format: .number)
            .font(Font(Self.font))
            .tracking(CinemaTheme.TopTen.numberTracking)
    }

    var body: some View {
        ZStack {
            ForEach(Self.outlineOffsets.indices, id: \.self) { index in
                number
                    .foregroundStyle(CinemaTheme.TopTen.outlineColor)
                    .offset(Self.outlineOffsets[index])
            }

            number
                .foregroundStyle(CinemaTheme.TopTen.numberFill)
        }
        .fixedSize()
        .frame(height: CinemaTheme.Card.height, alignment: .bottom)
        // Sit the digits on the poster's bottom edge rather than the font's descender line
        .offset(y: -Self.font.descender)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(rank, format: .number))
    }
}

/// Netflix's red "TOP 10" corner badge
struct CinemaTopTenBadge: View {

    @ObservedObject
    private var store = CinemaTopTenStore.shared

    let item: BaseItemDto
    let scale: CGFloat

    init(item: BaseItemDto, scale: CGFloat = 1) {
        self.item = item
        self.scale = scale
    }

    var body: some View {
        if store.contains(item) {
            VStack(spacing: -2 * scale) {
                Text(L10n.topBadge)
                    .font(.system(size: CinemaTheme.TopTen.badgeLabelSize * scale, weight: .heavy))

                Text(CinemaTopTenLibrary.count, format: .number)
                    .font(.system(size: CinemaTheme.TopTen.badgeNumberSize * scale, weight: .black))
            }
            .foregroundStyle(CinemaTheme.Colors.primaryText)
            .frame(
                width: CinemaTheme.TopTen.badgeWidth * scale,
                height: CinemaTheme.TopTen.badgeHeight * scale
            )
            .background(CinemaTheme.Colors.accent)
            .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: CinemaTheme.NewContent.cornerRadius * scale))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(L10n.topTen)
        }
    }
}
