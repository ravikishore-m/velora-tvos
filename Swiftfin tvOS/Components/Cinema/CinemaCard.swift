//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ButtonStyle where Self == CinemaCardButtonStyle {

    static var cinemaCard: CinemaCardButtonStyle {
        CinemaCardButtonStyle()
    }
}

/// Focus is shown by the card expanding, so only a press effect is applied here
struct CinemaCardButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? CinemaTheme.Focus.pressedScale : 1)
            .animation(CinemaTheme.Focus.animation, value: configuration.isPressed)
    }
}

struct CinemaCard: View {

    let entry: ItemEntry
    let isExpanded: Bool
    var showsTopTenBadge: Bool = true
    /// Position in a chart row, shown in a glass tile on the artwork
    var rank: Int?

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: CinemaTheme.Card.cornerRadius)
    }

    @ViewBuilder
    private func newContentBadge(for item: BaseItemDto) -> some View {
        if let label = item.cinemaNewContentLabel {
            CinemaNewContentPill(label: label)
                .padding(CinemaTheme.NewContent.inset)
        }
    }

    @ViewBuilder
    private var poster: some View {
        PosterImage(
            item: entry,
            type: .portrait,
            size: .medium
        )
        .frame(
            width: CinemaTheme.Card.portraitWidth,
            height: CinemaTheme.Card.height
        )
    }

    @ViewBuilder
    private func progressBar(for item: BaseItemDto) -> some View {
        if let percentage = item.progressPercentage {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(CinemaTheme.Colors.track)

                    Rectangle()
                        .fill(CinemaTheme.Brand.gradient)
                        .frame(width: proxy.size.width * percentage)
                }
            }
            .frame(height: CinemaTheme.Card.progressHeight)
        }
    }

    @ViewBuilder
    private func logo(for item: BaseItemDto) -> some View {
        ImageView(
            item.cinemaLogoSource(
                maxWidth: CinemaTheme.Card.logoMaxWidth,
                maxHeight: CinemaTheme.Card.logoMaxHeight
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
                .font(.title3.weight(.bold))
                .foregroundStyle(CinemaTheme.Colors.primaryText)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .frame(
            maxWidth: CinemaTheme.Card.logoMaxWidth,
            maxHeight: CinemaTheme.Card.logoMaxHeight,
            alignment: .bottomLeading
        )
        .accessibilityLabel(item.cinemaTitle)
    }

    /// Always loaded so expanding only crossfades instead of waiting on the network
    @ViewBuilder
    private func landscapeImage(for item: BaseItemDto) -> some View {
        ImageView(item.cinemaLandscapeSources(maxWidth: CinemaTheme.Card.imageMaxWidth))
            .image { (image: Image) in
                image
                    .aspectRatio(contentMode: .fill)
            }
            .failure {
                CinemaTheme.Colors.placeholder
            }
            .frame(
                width: CinemaTheme.Card.expandedWidth,
                height: CinemaTheme.Card.height
            )
            .clipped()
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private func billboard(for item: BaseItemDto) -> some View {
        ZStack(alignment: .bottomLeading) {
            CinemaTheme.Card.scrim

            // Only the title while browsing; details live on the item page
            VStack(alignment: .leading, spacing: CinemaTheme.Card.contentSpacing) {
                logo(for: item)

                progressBar(for: item)
            }
            .padding(CinemaTheme.Card.contentPadding)
            .frame(
                width: CinemaTheme.Card.expandedWidth,
                alignment: .leading
            )
        }
        .frame(
            width: CinemaTheme.Card.expandedWidth,
            height: CinemaTheme.Card.height
        )
    }

    var body: some View {
        let item = entry.snapshot

        ZStack(alignment: .topLeading) {
            landscapeImage(for: item)
                .opacity(isExpanded ? 1 : 0)

            poster
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 0) {
                        newContentBadge(for: item)
                        progressBar(for: item)
                    }
                }
                .overlay(alignment: .topTrailing) {
                    if showsTopTenBadge {
                        CinemaTopTenBadge(item: item)
                            .padding(CinemaTheme.Rank.inset)
                    }
                }
                .opacity(isExpanded ? 0 : 1)

            if isExpanded {
                billboard(for: item)
                    .transition(.opacity.combined(with: .offset(y: 12)))
            }

            if let rank {
                CinemaRankTag(rank: rank)
                    .padding(CinemaTheme.Rank.inset)
            }
        }
        .frame(
            width: isExpanded ? CinemaTheme.Card.expandedWidth : CinemaTheme.Card.portraitWidth,
            height: CinemaTheme.Card.height,
            alignment: .topLeading
        )
        .background(CinemaTheme.Colors.placeholder)
        .clipShape(shape)
        .overlay {
            shape
                .strokeBorder(CinemaTheme.Brand.diagonalGradient, lineWidth: 3)
                .opacity(isExpanded ? 1 : 0)
        }
        .shadow(
            color: .black.opacity(isExpanded ? 0.6 : 0),
            radius: CinemaTheme.Focus.shadowRadius,
            y: 10
        )
        .environment(\.colorScheme, .dark)
        .accessibilityElement(children: .combine)
    }
}
