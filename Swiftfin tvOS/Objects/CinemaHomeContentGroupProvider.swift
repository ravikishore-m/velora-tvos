//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import FactoryKit
import Foundation
import JellyfinAPI

struct CinemaHomeContentGroupProvider: ContentGroupProvider {

    @Injected(\.currentUserSession)
    var userSession: UserSession?

    let displayTitle: String = L10n.home
    let id: String = "cinema-home-content-group-provider"

    func makeGroups(environment: Empty) async throws -> [any ContentGroup] {
        guard let userSession else { return [] }

        let parameters = Paths.GetUserViewsParameters(userID: userSession.user.id)
        let userViewsPath = Paths.getUserViews(parameters: parameters)
        let userViews = try await userSession.send(userViewsPath)
        let excludedLibraryIDs = userSession.user.data.configuration?.latestItemsExcludes ?? []

        // Movies and shows have dedicated rows
        let otherVideoLibraries = (userViews.value.items ?? [])
            .subtracting(excludedLibraryIDs, using: \.id)
            .intersecting(
                [
                    .homevideos,
                    .musicvideos,
                ],
                using: \.collectionType
            )

        return _makeGroups(otherVideoLibraries: otherVideoLibraries)
    }

    @ContentGroupBuilder
    private func _makeGroups(otherVideoLibraries: [BaseItemDto]) -> [any ContentGroup] {

        let continueWatching = PosterGroup(
            id: "cinema-continue-watching",
            library: ResumeItemsLibrary(mediaTypes: [.video]),
            posterDisplayType: .landscape,
            posterSize: .medium,
            _viewContext: .isInResume
        )

        let recentlyAddedMovies = PosterGroup(
            id: "cinema-recently-added-movies",
            library: ItemLibrary(
                parent: BaseItemDto(name: L10n.recentlyAddedMovies),
                filters: .init(
                    itemTypes: [.movie],
                    sortBy: [.dateCreated],
                    sortOrder: [.descending]
                )
            )
        )

        CinemaHeroContentGroup(
            resumeViewModel: continueWatching.viewModel,
            fallbackViewModel: recentlyAddedMovies.viewModel
        )

        continueWatching

        PosterGroup(
            id: "cinema-next-up",
            library: NextUpLibrary(),
            posterDisplayType: .landscape,
            posterSize: .medium
        )

        if Defaults[.Customization.Home.showRecentlyAdded] {
            recentlyAddedMovies

            PosterGroup(
                id: "cinema-recently-added-episodes",
                library: ItemLibrary(
                    parent: BaseItemDto(name: L10n.recentlyAddedEpisodes),
                    filters: .init(
                        itemTypes: [.episode],
                        sortBy: [.dateCreated],
                        sortOrder: [.descending]
                    )
                ),
                posterDisplayType: .landscape,
                posterSize: .medium
            )
        }

        if Defaults[.Customization.Home.showRecentlyPlayed] {
            PosterGroup(
                id: "cinema-recently-played",
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

        PosterGroup(
            id: "cinema-movies",
            library: ItemLibrary(
                parent: BaseItemDto(name: L10n.movies),
                filters: .init(
                    itemTypes: [.movie],
                    sortBy: [.premiereDate],
                    sortOrder: [.descending]
                )
            )
        )

        PosterGroup(
            id: "cinema-tv-shows",
            library: ItemLibrary(
                parent: BaseItemDto(name: L10n.tvShowsCapitalized),
                filters: .init(
                    itemTypes: [.series],
                    sortBy: [.dateLastContentAdded],
                    sortOrder: [.descending]
                )
            )
        )

        PosterGroup(
            id: "cinema-programs-recommended",
            library: RecommendedProgramsLibrary(),
            posterDisplayType: .landscape,
            posterSize: .small
        )

        otherVideoLibraries
            .map(LatestInLibrary.init)
            .map {
                PosterGroup(
                    id: "cinema-latest-\($0.parent.id ?? $0.parent.displayTitle)",
                    library: $0,
                    posterDisplayType: .landscape
                )
            }
    }
}
