//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct CinemaRowContentGroup<Library: PagingLibrary>: ContentGroup where Library.Element == ItemEntry {

    let displayTitle: String
    let id: String
    let isRanked: Bool
    /// Rows with fewer titles are hidden rather than shown half-empty
    let minimumCount: Int
    let viewModel: PagingLibraryViewModel<Library>

    var _shouldBeResolved: Bool {
        viewModel.elements.count >= max(1, minimumCount)
    }

    init(
        id: String,
        library: Library,
        displayTitle: String? = nil,
        isRanked: Bool = false,
        minimumCount: Int = 1
    ) {
        self.displayTitle = displayTitle ?? library.parent.displayTitle
        self.id = id
        self.isRanked = isRanked
        self.minimumCount = minimumCount
        self.viewModel = .init(library: library, pageSize: 20)
    }

    func body(with viewModel: PagingLibraryViewModel<Library>) -> some View {
        CinemaCarousel(
            viewModel: viewModel,
            title: displayTitle,
            rankingID: isRanked ? id : nil
        )
    }
}
