//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

/// Features the first Continue Watching item, falling back to the newest movie.
///
/// Both view models are shared with their rows so the hero does not issue its own requests.
/// The fallback view model is owned here so it is still refreshed when its row is hidden.
struct CinemaHeroContentGroup: ContentGroup {

    let id = "cinema-hero"
    let resumeViewModel: PagingLibraryViewModel<ResumeItemsLibrary>
    let viewModel: PagingLibraryViewModel<ItemLibrary>

    var _shouldBeResolved: Bool {
        resumeViewModel.elements.isNotEmpty || viewModel.elements.isNotEmpty
    }

    init(
        resumeViewModel: PagingLibraryViewModel<ResumeItemsLibrary>,
        fallbackViewModel: PagingLibraryViewModel<ItemLibrary>
    ) {
        self.resumeViewModel = resumeViewModel
        self.viewModel = fallbackViewModel
    }

    func body(with viewModel: PagingLibraryViewModel<ItemLibrary>) -> some View {
        CinemaHeroBanner(
            resumeViewModel: resumeViewModel,
            fallbackViewModel: viewModel
        )
    }
}
