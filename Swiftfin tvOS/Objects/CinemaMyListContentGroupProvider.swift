//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

/// My Velora, the viewer's personal hub: their profile, in-progress items, favorites and recently played titles
struct CinemaMyListContentGroupProvider: ContentGroupProvider {

    let displayTitle: String = L10n.myVelora
    let id: String = "cinema-my-list-content-group-provider"

    func makeGroups(environment: Empty) async throws -> [any ContentGroup] {
        _makeGroups()
    }

    @ContentGroupBuilder
    private func _makeGroups() -> [any ContentGroup] {
        CinemaProfileHeaderGroup()

        CinemaRowContentGroup(
            id: "cinema-my-list-continue-watching",
            library: ResumeItemsLibrary(mediaTypes: [.video])
        )

        CinemaRowContentGroup(
            id: "cinema-my-list-favorite-movies",
            library: ItemLibrary(
                parent: BaseItemDto(name: L10n.favoriteMovies),
                filters: .init(
                    itemTypes: [.movie],
                    sortBy: [.sortName],
                    traits: [.isFavorite]
                )
            )
        )

        CinemaRowContentGroup(
            id: "cinema-my-list-favorite-shows",
            library: ItemLibrary(
                parent: BaseItemDto(name: L10n.favoriteShows),
                filters: .init(
                    itemTypes: [.series],
                    sortBy: [.sortName],
                    traits: [.isFavorite]
                )
            )
        )

        CinemaRowContentGroup(
            id: "cinema-my-list-recently-played",
            library: ItemLibrary(
                parent: BaseItemDto(name: L10n.recentlyPlayed.localizedCapitalized),
                filters: .init(
                    itemTypes: [.movie, .series],
                    sortBy: [.datePlayed],
                    sortOrder: [.descending],
                    traits: [.isPlayed]
                )
            )
        )
    }
}
