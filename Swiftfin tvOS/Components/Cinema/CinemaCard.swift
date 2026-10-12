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

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: CinemaTheme.Card.cornerRadius)
    }

    @ViewBuilder
    private func newContentBadge(for item: BaseItemDto) -> some View {
        if let label = item.cinemaNewContentLabel {
            Text(label)
                .font(.system(size: CinemaTheme.NewContent.fontSize, weight: .bold))
                .foregroundStyle(CinemaTheme.Colors.primaryText)
                .lineLimit(1)
                .padding(.horizontal, CinemaTheme.NewContent.horizontalPadding)
                .padding(.vertical, CinemaTheme.NewContent.verticalPadding)
                .background(CinemaTheme.Colors.accent)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: CinemaTheme.NewContent.cornerRadius,
                        topTrailingRadius: CinemaTheme.NewContent.cornerRadius
                    )
                )
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
                        .fill(CinemaTheme.Colors.actionBackground)

                    Rectangle()
                        .fill(CinemaTheme.Colors.accent)
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

            VStack(alignment: .leading, spacing: CinemaTheme.Card.contentSpacing) {
                logo(for: item)

                if item.type == .episode {
                    Text(item.displayTitle)
                        .font(CinemaTheme.Typography.metadata)
                        .foregroundStyle(CinemaTheme.Colors.primaryText)
                        .lineLimit(1)
                }

                HStack(spacing: CinemaTheme.Badge.spacing) {
                    CinemaTopTenBadge(item: item, scale: CinemaTheme.TopTen.inlineBadgeScale)

                    if let label = item.cinemaNewContentLabel {
                        Text(label)
                            .font(CinemaTheme.Typography.metadata)
                            .foregroundStyle(CinemaTheme.Colors.accent)
                            .lineLimit(1)
                    }
                }

                if let overview = item.overview, overview.isNotEmpty {
                    Text(overview)
                        .font(.caption)
                        .foregroundStyle(CinemaTheme.Colors.secondaryText)
                        .lineLimit(CinemaTheme.Card.synopsisLineLimit)
                        .multilineTextAlignment(.leading)
                }

                CinemaBadges(item: item, formats: .summary, fitsContainer: true)

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
                .overlay(alignment: .bottom) {
                    VStack(spacing: 0) {
                        newContentBadge(for: item)
                        progressBar(for: item)
                    }
                }
                .overlay(alignment: .topTrailing) {
                    if showsTopTenBadge {
                        CinemaTopTenBadge(item: item)
                    }
                }
                .opacity(isExpanded ? 0 : 1)

            if isExpanded {
                billboard(for: item)
                    .transition(.opacity.combined(with: .offset(y: 12)))
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
                .strokeBorder(CinemaTheme.Colors.primaryText.opacity(isExpanded ? 0.35 : 0), lineWidth: 2)
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
