//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

/// Rotates through a random selection of unwatched movies and shows,
/// falling back to the newest movies when everything has been watched.
///
/// The fallback view model is shared with its row so it does not issue its own request.
struct CinemaHeroContentGroup: ContentGroup {

    let id = "cinema-hero"
    let fallbackViewModel: PagingLibraryViewModel<ItemLibrary>
    let viewModel: PagingLibraryViewModel<ItemLibrary>

    var _shouldBeResolved: Bool {
        viewModel.elements.isNotEmpty || fallbackViewModel.elements.isNotEmpty
    }

    init(fallbackViewModel: PagingLibraryViewModel<ItemLibrary>) {
        self.fallbackViewModel = fallbackViewModel
        self.viewModel = .init(
            library: ItemLibrary(
                parent: BaseItemDto(name: L10n.featured),
                filters: .init(
                    itemTypes: [.movie, .series],
                    sortBy: [.random],
                    traits: [.isUnplayed]
                )
            ),
            pageSize: 20
        )
    }

    func body(with viewModel: PagingLibraryViewModel<ItemLibrary>) -> some View {
        CinemaHeroBanner(
            featuredViewModel: viewModel,
            fallbackViewModel: fallbackViewModel
        )
        .preference(
            key: ContentGroupCustomizationKey.self,
            value: .ignoreSafeAreaTop
        )
    }
}
