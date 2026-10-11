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
    let viewModel: PagingLibraryViewModel<Library>

    var _shouldBeResolved: Bool {
        viewModel.elements.isNotEmpty
    }

    init(
        id: String,
        library: Library,
        displayTitle: String? = nil
    ) {
        self.displayTitle = displayTitle ?? library.parent.displayTitle
        self.id = id
        self.viewModel = .init(library: library, pageSize: 20)
    }

    func body(with viewModel: PagingLibraryViewModel<Library>) -> some View {
        CinemaCarousel(
            viewModel: viewModel,
            title: displayTitle
        )
    }
}
