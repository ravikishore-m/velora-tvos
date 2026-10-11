//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

/// A row of portrait posters where the focused poster expands into a landscape card
struct CinemaCarousel<Library: PagingLibrary>: View where Library.Element == ItemEntry {

    private struct CardButton: View {

        @Namespace
        private var namespace

        @Router
        private var router

        let entry: ItemEntry
        let isExpanded: Bool

        var body: some View {
            Button {
                entry.libraryDidSelectElement(router: router, in: namespace)
            } label: {
                CinemaCard(
                    entry: entry,
                    isExpanded: isExpanded
                )
            }
            .buttonStyle(.cinemaCard)
            .posterContextMenu(for: entry) {
                PosterImage(
                    item: entry,
                    type: .portrait,
                    size: .medium
                )
                .frame(width: CinemaTheme.Card.portraitWidth)
            }
            .matchedTransitionSource(id: "item", in: namespace)
        }
    }

    @FocusState
    private var focusedID: ItemEntry.ID?

    @ObservedObject
    var viewModel: PagingLibraryViewModel<Library>

    let title: String

    /// Begin loading the next page while a few cards remain
    private static var prefetchDistance: Int {
        5
    }

    private func loadMoreIfNeeded(after entry: ItemEntry) {
        let elements = viewModel.elements.elements

        guard let index = elements.firstIndex(where: { $0.id == entry.id }),
              index >= elements.count - Self.prefetchDistance
        else { return }

        viewModel.getNextPage()
    }

    @ViewBuilder
    private func card(for entry: ItemEntry) -> some View {
        CardButton(
            entry: entry,
            isExpanded: focusedID == entry.id
        )
        .focused($focusedID, equals: entry.id)
        .id(entry.id)
        .onAppear {
            loadMoreIfNeeded(after: entry)
        }
    }

    var body: some View {
        if viewModel.elements.isNotEmpty {
            VStack(alignment: .leading, spacing: CinemaTheme.Card.headerSpacing) {
                Text(title)
                    .font(CinemaTheme.Typography.rowTitle)
                    .foregroundStyle(CinemaTheme.Colors.primaryText)
                    .lineLimit(1)
                    .padding(.horizontal, CinemaTheme.Spacing.edge)
                    .accessibilityAddTraits(.isHeader)

                ScrollViewReader { proxy in
                    ScrollView(.horizontal) {
                        LazyHStack(alignment: .top, spacing: CinemaTheme.Card.spacing) {
                            ForEach(viewModel.elements.elements) { entry in
                                card(for: entry)
                            }
                        }
                    }
                    .contentMargins(.horizontal, CinemaTheme.Spacing.edge, for: .scrollContent)
                    .scrollIndicators(.hidden)
                    .scrollClipDisabled()
                    .onChange(of: focusedID) { _, newValue in
                        guard let newValue else { return }

                        withAnimation(CinemaTheme.Card.expandAnimation) {
                            proxy.scrollTo(newValue, anchor: .leading)
                        }
                    }
                }
            }
            .focusSection()
            .animation(CinemaTheme.Card.expandAnimation, value: focusedID)
            .environment(\.colorScheme, .dark)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(title)
        }
    }
}
