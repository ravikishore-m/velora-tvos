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
    private var topTenStore = CinemaTopTenStore.shared

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

    /// Inset, rounded billboard below the tab bar
    private var cardSize: CGSize {
        CGSize(
            width: max(parentSize.width - CinemaTheme.Spacing.edge * 2, 1),
            height: max(
                heroHeight - CinemaTheme.Hero.cardTopInset - CinemaTheme.Hero.indicatorSpacing - CinemaTheme.Hero.indicatorHeight,
                1
            )
        )
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
            size: cardSize
        )
        .overlay {
            CinemaTheme.Hero.leadingScrim
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
                Capsule()
                    .fill(CinemaTheme.Colors.track)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(CinemaTheme.Brand.gradient)
                            .frame(width: CinemaTheme.Hero.progressWidth * percentage)
                    }
                    .frame(width: CinemaTheme.Hero.progressWidth, height: 8)
                    .accessibilityHidden(true)

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
            CinemaNewContentTag(item: item)

            title(for: item)
                .padding(.bottom, CinemaTheme.Spacing.metadata)

            if item.type == .episode {
                Text(item.displayTitle)
                    .font(CinemaTheme.Typography.metadata)
                    .foregroundStyle(CinemaTheme.Colors.primaryText)
                    .lineLimit(1)
            }

            CinemaFactsLine(item: item)

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

    /// Corner chips: the audio languages on offer and the title's Top 10 position
    @ViewBuilder
    private func chips(for item: BaseItemDto) -> some View {
        let languages = item.cinemaAudioLanguageCodes
        let ranking = topTenStore.ranking(of: item)

        HStack(spacing: CinemaTheme.Hero.chipSpacing) {
            if languages.count > 1 {
                HeroChip(
                    glyph: .channels,
                    title: L10n.inLanguages(
                        languages
                            .prefix(CinemaTheme.Hero.maximumChipLanguages)
                            .map(\.localizedCapitalized)
                            .joined(separator: ", ")
                    )
                )
            }

            if let ranking {
                HeroChip(
                    glyph: .sound,
                    title: ranking.rowID == CinemaTopTenStore.showsRowID ?
                        L10n.rankInShows(ranking.rank) :
                        L10n.rankInMovies(ranking.rank)
                )
            }
        }
    }

    @ViewBuilder
    private func card(for item: BaseItemDto, warming nextItem: BaseItemDto) -> some View {
        ZStack(alignment: .bottomLeading) {
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
            .frame(width: cardSize.width, height: cardSize.height)
            .clipped()
            .allowsHitTesting(false)

            CinemaTheme.Hero.bottomScrim
                .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: CinemaTheme.Spacing.heroContent) {
                // Outgoing and incoming titles share one slot instead of stacking during the swap
                ZStack(alignment: .bottomLeading) {
                    details(for: item)
                        .id(item.id)
                        .transition(CinemaTheme.Hero.detailsTransition)
                }

                // Labels swap instantly so "Play" and "Resume" never blend together
                actions(for: item)
                    .animation(nil, value: item.id)
            }
            .padding(CinemaTheme.Hero.cardContentPadding)

            ZStack(alignment: .bottomTrailing) {
                chips(for: item)
                    .id(item.id)
                    .transition(CinemaTheme.Hero.detailsTransition)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(CinemaTheme.Hero.cardContentPadding)
        }
        .frame(width: cardSize.width, height: cardSize.height)
        .clipShape(RoundedRectangle(cornerRadius: CinemaTheme.Hero.cardCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: CinemaTheme.Hero.cardCornerRadius, style: .continuous)
                .strokeBorder(.white.opacity(0.14), lineWidth: 1.5)
        }
        .shadow(color: CinemaTheme.Brand.violet.opacity(0.25), radius: 40, y: 16)
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
        .fixedSize(horizontal: true, vertical: true)
        .focusSection()
        .onMoveCommand(perform: handleMove)
    }

    @ViewBuilder
    private var pageIndicator: some View {
        if items.count > 1 {
            HStack(spacing: 10) {
                ForEach(items.indices, id: \.self) { page in
                    Capsule()
                        .fill(page == index ? AnyShapeStyle(CinemaTheme.Brand.gradient) : AnyShapeStyle(CinemaTheme.Colors.tertiaryText))
                        .frame(width: page == index ? 36 : 10, height: 10)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .glassEffect(.regular, in: Capsule())
            .animation(CinemaTheme.Hero.crossfade, value: index)
            .accessibilityHidden(true)
        }
    }

    var body: some View {
        let items = items

        if items.isNotEmpty {
            let item = items[min(index, items.count - 1)]
            let nextItem = items[(min(index, items.count - 1) + 1) % items.count]

            VStack(alignment: .leading, spacing: CinemaTheme.Hero.indicatorSpacing) {
                CinemaHomeTopBar()
                    .frame(height: CinemaTheme.Hero.cardTopInset - CinemaTheme.Hero.indicatorSpacing)

                card(for: item, warming: nextItem)

                pageIndicator
                    .padding(.leading, CinemaTheme.Hero.cardContentPadding)
            }
            .padding(.horizontal, CinemaTheme.Spacing.edge)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .frame(height: heroHeight, alignment: .top)
            .environment(\.colorScheme, .dark)
            .onChange(of: items.map(\.id), initial: true) {
                CinemaFeaturedArtwork.remember(items)
            }
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

    /// A glass capsule led by a Velora glyph
    private struct HeroChip: View {

        let glyph: VeloraFormatGlyph
        let title: String

        var body: some View {
            HStack(spacing: CinemaTheme.Hero.chipIconSpacing) {
                VeloraFormatGlyphView(glyph: glyph, size: CinemaTheme.Hero.chipIconSize)

                Text(title)
                    .font(CinemaTheme.Hero.chipFont)
                    .foregroundStyle(CinemaTheme.Colors.primaryText)
                    .lineLimit(1)
            }
            .padding(.horizontal, CinemaTheme.Hero.chipPadding)
            .padding(.vertical, CinemaTheme.Hero.chipPadding / 2)
            .glassEffect(.regular, in: Capsule())
            .accessibilityElement(children: .combine)
        }
    }

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
