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
    private var index = 0
    @State
    private var lastFocusChange = Date.distantPast
    @State
    private var scrollViewReference = ScrollViewReference()

    @ObservedObject
    var featuredViewModel: PagingLibraryViewModel<ItemLibrary>
    @ObservedObject
    var fallbackViewModel: PagingLibraryViewModel<ItemLibrary>

    /// Only titles with backdrop art, so the hero is never a stretched poster
    private var items: [BaseItemDto] {
        let featured = featuredViewModel.elements
            .elements
            .map(\.snapshot)
            .filter { $0.backdropImageTags?.isNotEmpty == true }

        let source = featured.isEmpty ? fallbackViewModel.elements.elements.map(\.snapshot) : featured

        return Array(source.prefix(CinemaTheme.Hero.maximumItems))
    }

    private var parentSize: CGSize {
        frameForParentView[.scrollView, default: .zero].frame.size
    }

    private var heroHeight: CGFloat {
        max(parentSize.height * CinemaTheme.Hero.heightRatio, CinemaTheme.Hero.minimumHeight)
    }

    /// Backdrops are drawn at their native 16:9 so nothing is cropped
    private var backdropSize: CGSize {
        let width = max(parentSize.width, 1)
        return CGSize(width: width, height: width * 9 / 16)
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

    private func advance(by offset: Int) {
        let count = items.count
        guard count > 1 else { return }

        withAnimation(CinemaTheme.Hero.crossfade) {
            index = ((index + offset) % count + count) % count
        }
    }

    /// Left/right at the ends of the button row browses featured titles.
    ///
    /// A move that also changed focus was handled by the focus engine and is ignored.
    private func handleMove(_ direction: MoveCommandDirection) {
        let offset: Int

        switch direction {
        case .left: offset = -1
        case .right: offset = 1
        default: return
        }

        let moveTime = Date()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            guard abs(lastFocusChange.timeIntervalSince(moveTime)) > 0.2 else { return }

            advance(by: offset)
        }
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
        KenBurnsImage(
            sources: item.cinemaLandscapeSources(maxWidth: CinemaTheme.Hero.backdropMaxWidth),
            size: backdropSize
        )
        .overlay {
            CinemaTheme.Hero.leadingScrim
        }
        .mask(gradient: .linear) {
            (location: CinemaTheme.Hero.backdropFadeStart, opacity: 1)
            (location: 1, opacity: 0)
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
                    .tint(CinemaTheme.Colors.accent)
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
    private func details(for item: BaseItemDto) -> some View {
        VStack(alignment: .leading, spacing: CinemaTheme.Spacing.metadata) {
            title(for: item)
                .padding(.bottom, CinemaTheme.Spacing.metadata)

            if item.type == .episode {
                Text(item.displayTitle)
                    .font(CinemaTheme.Typography.metadata)
                    .foregroundStyle(CinemaTheme.Colors.primaryText)
                    .lineLimit(1)
            }

            CinemaBadges(item: item, includesAudio: true)

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
        .frame(maxWidth: .infinity, alignment: .bottomLeading)
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
        .onMoveCommand(perform: handleMove)
    }

    @ViewBuilder
    private var pageIndicator: some View {
        if items.count > 1 {
            HStack(spacing: 10) {
                ForEach(items.indices, id: \.self) { page in
                    Capsule()
                        .fill(page == index ? CinemaTheme.Colors.primaryText : CinemaTheme.Colors.tertiaryText)
                        .frame(width: page == index ? 36 : 10, height: 10)
                }
            }
            .animation(CinemaTheme.Hero.crossfade, value: index)
            .accessibilityHidden(true)
        }
    }

    var body: some View {
        let items = items

        if items.isNotEmpty {
            let item = items[min(index, items.count - 1)]
            let nextItem = items[(min(index, items.count - 1) + 1) % items.count]

            VStack(alignment: .leading, spacing: CinemaTheme.Spacing.heroContent) {
                Spacer(minLength: 0)

                details(for: item)
                    .id(item.id)
                    .transition(.opacity)

                actions(for: item)

                pageIndicator
            }
            .padding(.horizontal, CinemaTheme.Spacing.edge)
            .padding(.bottom, CinemaTheme.Hero.contentBottomPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: heroHeight)
            .background(alignment: .top) {
                ZStack {
                    // Warms the image cache so the next crossfade is instant
                    if nextItem.id != item.id {
                        backdrop(for: nextItem)
                            .opacity(0)
                    }

                    backdrop(for: item)
                        .id(item.id)
                        .transition(.opacity)
                }
                .frame(width: backdropSize.width, height: backdropSize.height, alignment: .top)
                .allowsHitTesting(false)
            }
            .environment(\.colorScheme, .dark)
            .animation(CinemaTheme.Hero.crossfade, value: item.id)
            .task(id: [index, items.count]) {
                try? await Task.sleep(for: CinemaTheme.Hero.rotationInterval)

                guard !Task.isCancelled else { return }

                advance(by: 1)
            }
            .introspect(.scrollView, on: .tvOS(.v26...), scope: .ancestor) { scrollView in
                scrollViewReference.scrollView = scrollView
            }
            .onChange(of: focusedAction) { _, newValue in
                lastFocusChange = Date()

                guard newValue != nil else { return }

                scrollToTop()
            }
            .onChange(of: items.count) { _, newValue in
                if index >= newValue {
                    index = 0
                }
            }
        }
    }
}

extension CinemaHeroBanner {

    /// Slowly zooms the backdrop while it is on screen
    private struct KenBurnsImage: View {

        @State
        private var isZoomed = false

        let sources: [ImageSource]
        let size: CGSize

        var body: some View {
            ImageView(sources)
                .image { (image: Image) in
                    image
                        .aspectRatio(contentMode: .fill)
                }
                .failure {
                    CinemaTheme.Colors.placeholder
                }
                .frame(width: size.width, height: size.height)
                .scaleEffect(isZoomed ? CinemaTheme.Hero.zoomScale : 1, anchor: .topTrailing)
                .clipped()
                .onAppear {
                    withAnimation(.linear(duration: CinemaTheme.Hero.zoomDuration)) {
                        isZoomed = true
                    }
                }
        }
    }
}
