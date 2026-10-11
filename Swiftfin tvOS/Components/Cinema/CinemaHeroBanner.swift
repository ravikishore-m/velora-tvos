//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI
import SwiftUIIntrospect

struct CinemaHeroBanner: View {

    private enum Action: Hashable {
        case play
        case moreInfo
    }

    private final class ScrollViewReference {
        weak var scrollView: UIScrollView?
    }

    @Environment(\.frameForParentView)
    private var frameForParentView

    @FocusState
    private var focusedAction: Action?

    @Router
    private var router

    @State
    private var scrollViewReference = ScrollViewReference()

    @ObservedObject
    var resumeViewModel: PagingLibraryViewModel<ResumeItemsLibrary>
    @ObservedObject
    var fallbackViewModel: PagingLibraryViewModel<ItemLibrary>

    private var featuredItem: BaseItemDto? {
        (resumeViewModel.elements.first ?? fallbackViewModel.elements.first)?.snapshot
    }

    private var heroHeight: CGFloat {
        let parentHeight = frameForParentView[.scrollView, default: .zero].frame.height

        return max(parentHeight * CinemaTheme.Hero.heightRatio, CinemaTheme.Hero.minimumHeight)
    }

    // MARK: - Actions

    private func play(_ item: BaseItemDto) {
        guard let provider = item.getPlaybackItemProvider(userSession: nil) else {
            router.route(to: .item(item: item))
            return
        }

        let queue: (any MediaPlayerQueue)? = item.type == .episode ? EpisodeMediaPlayerQueue(episode: item) : nil

        router.route(
            to: .videoPlayer(
                provider: provider,
                queue: queue
            )
        )
    }

    private func scrollToTop() {
        guard let scrollView = scrollViewReference.scrollView else { return }

        let topOffset = CGPoint(
            x: scrollView.contentOffset.x,
            y: -scrollView.adjustedContentInset.top
        )

        guard scrollView.contentOffset.y > topOffset.y else { return }

        scrollView.setContentOffset(topOffset, animated: true)
    }

    // MARK: - Views

    @ViewBuilder
    private func backdrop(for item: BaseItemDto) -> some View {
        ImageView(item.cinemaLandscapeSources(maxWidth: CinemaTheme.Hero.backdropMaxWidth))
            .image { (image: Image) in
                image
                    .aspectRatio(contentMode: .fill)
            }
            .failure {
                CinemaTheme.Colors.placeholder
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .overlay {
                CinemaTheme.Hero.leadingScrim
            }
            .overlay {
                CinemaTheme.Hero.bottomScrim
            }
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private func title(for item: BaseItemDto) -> some View {
        ImageView(
            item.cinemaLogoSource(
                maxWidth: CinemaTheme.Hero.logoMaxWidth,
                maxHeight: CinemaTheme.Hero.logoMaxHeight
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
                .font(CinemaTheme.Typography.heroTitle)
                .foregroundStyle(CinemaTheme.Colors.primaryText)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .frame(
            maxWidth: CinemaTheme.Hero.logoMaxWidth,
            maxHeight: CinemaTheme.Hero.logoMaxHeight,
            alignment: .bottomLeading
        )
        .accessibilityLabel(item.cinemaTitle)
    }

    @ViewBuilder
    private func progress(for item: BaseItemDto) -> some View {
        if let percentage = item.progressPercentage {
            HStack(spacing: CinemaTheme.Spacing.metadata) {
                ProgressView(value: percentage)
                    .progressViewStyle(.linear)
                    .tint(CinemaTheme.Colors.progress)
                    .frame(width: CinemaTheme.Hero.progressWidth)

                if let progressLabel = item.progressLabel {
                    Text(progressLabel)
                        .font(CinemaTheme.Typography.metadata)
                        .foregroundStyle(CinemaTheme.Colors.secondaryText)
                }
            }
        }
    }

    @ViewBuilder
    private func actions(for item: BaseItemDto) -> some View {
        let hasProgress = (item.userData?.playbackPositionTicks ?? 0) > 0

        HStack(spacing: CinemaTheme.Spacing.actions) {
            if item.isPlayable {
                Button {
                    play(item)
                } label: {
                    Label(
                        hasProgress ? L10n.resume : L10n.play,
                        systemImage: "play.fill"
                    )
                }
                .focused($focusedAction, equals: .play)
            }

            Button {
                router.route(to: .item(item: item))
            } label: {
                Label(L10n.moreInfo, systemImage: "info.circle")
            }
            .focused($focusedAction, equals: .moreInfo)
        }
        .buttonStyle(.cinemaAction)
        .focusSection()
    }

    @ViewBuilder
    private func details(for item: BaseItemDto) -> some View {
        VStack(alignment: .leading, spacing: CinemaTheme.Spacing.heroContent) {
            title(for: item)

            VStack(alignment: .leading, spacing: CinemaTheme.Spacing.metadata) {
                if item.type == .episode {
                    Text(item.displayTitle)
                        .font(CinemaTheme.Typography.metadata)
                        .foregroundStyle(CinemaTheme.Colors.primaryText)
                        .lineLimit(1)
                }

                CinemaBadges(item: item)

                if let overview = item.overview, overview.isNotEmpty {
                    Text(overview)
                        .font(CinemaTheme.Typography.heroSynopsis)
                        .foregroundStyle(CinemaTheme.Colors.secondaryText)
                        .lineLimit(CinemaTheme.Hero.synopsisLineLimit)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: CinemaTheme.Hero.synopsisMaxWidth, alignment: .leading)
                }

                progress(for: item)
            }

            actions(for: item)
        }
        .frame(maxWidth: .infinity, alignment: .bottomLeading)
    }

    var body: some View {
        if let item = featuredItem {
            ZStack(alignment: .bottomLeading) {
                backdrop(for: item)

                details(for: item)
                    .padding(CinemaTheme.Hero.contentPadding)
            }
            .frame(maxWidth: .infinity)
            .frame(height: heroHeight)
            .background(CinemaTheme.Colors.placeholder)
            .clipShape(RoundedRectangle(cornerRadius: CinemaTheme.Hero.cornerRadius))
            .shadow(color: .black.opacity(0.5), radius: CinemaTheme.Focus.shadowRadius, y: 12)
            .padding(.horizontal, CinemaTheme.Spacing.edge)
            .environment(\.colorScheme, .dark)
            .animation(CinemaTheme.Focus.backdropTransition, value: item.id)
            .introspect(.scrollView, on: .tvOS(.v26...), scope: .ancestor) { scrollView in
                scrollViewReference.scrollView = scrollView
            }
            .onChange(of: focusedAction) { _, newValue in
                guard newValue != nil else { return }

                scrollToTop()
            }
        }
    }
}
