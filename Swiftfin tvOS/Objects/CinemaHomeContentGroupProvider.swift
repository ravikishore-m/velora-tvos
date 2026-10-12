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

/// Velora home: personal rows, Top 10 charts and categories built from what the server actually holds
struct CinemaHomeContentGroupProvider: ContentGroupProvider {

    private struct Category {
        let id: String
        let title: String
        let filters: ItemFilterCollection
    }

    private struct WatchedTitle {
        let id: String
        let name: String
        let type: BaseItemKind
    }

    private enum Limits {
        static let movieGenres = 8
        static let tvGenres = 4
        static let indianLanguages = 3
        static let worldLanguages = 2
        static let recentlyWatched = 2
    }

    /// Genres in order of prominence
    private static let movieGenrePriority = [
        "Action", "Comedy", "Thriller", "Romance", "Horror", "Science Fiction", "Animation",
        "Crime", "Drama", "Family", "Adventure", "Fantasy", "Mystery", "Documentary",
    ]

    private static let tvGenrePriority = [
        "Drama", "Comedy", "Crime", "Sci-Fi & Fantasy", "Action & Adventure",
        "Mystery", "Animation", "Documentary", "Reality", "Kids",
    ]

    /// ISO 639-2 codes, as reported by Jellyfin for audio streams
    private static let indianLanguages = ["hin", "tel", "tam", "mal", "kan", "ben", "mar", "pan", "guj"]
    private static let southIndianLanguages: Set = ["tel", "tam", "mal", "kan"]
    private static let worldLanguages = ["kor", "jpn", "spa", "fra", "fre", "deu", "ger", "ita", "zho", "chi", "tha"]

    @Injected(\.currentUserSession)
    var userSession: UserSession?

    let displayTitle: String = L10n.home
    let id: String = "cinema-home-content-group-provider"

    func makeGroups(environment: Empty) async throws -> [any ContentGroup] {
        guard let userSession else { return [] }

        async let movieFilters = queryFilters(for: .movie, userSession: userSession)
        async let seriesFilters = queryFilters(for: .series, userSession: userSession)
        async let recentlyWatched = recentlyWatchedTitles(userSession: userSession)

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

        let movieQueryFilters = await movieFilters
        let seriesQueryFilters = await seriesFilters

        return await _makeGroups(
            userName: userSession.user.username,
            serverName: userSession.server.name,
            recentlyWatched: recentlyWatched,
            movieGenres: movieGenreCategories(from: movieQueryFilters),
            tvGenres: tvGenreCategories(from: seriesQueryFilters),
            languages: languageCategories(from: movieQueryFilters),
            otherVideoLibraries: otherVideoLibraries
        )
    }

    // MARK: - Groups

    @ContentGroupBuilder
    private func _makeGroups(
        userName: String,
        serverName: String,
        recentlyWatched: [WatchedTitle],
        movieGenres: [Category],
        tvGenres: [Category],
        languages: [Category],
        otherVideoLibraries: [BaseItemDto]
    ) -> [any ContentGroup] {

        let recentlyAddedMovies = CinemaRowContentGroup(
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

        let leadingGenres = movieGenres.prefix(3)
        let trailingGenres = movieGenres.dropFirst(3)

        CinemaHeroContentGroup(
            fallbackViewModel: recentlyAddedMovies.viewModel
        )

        CinemaRowContentGroup(
            id: "cinema-continue-watching",
            library: ResumeItemsLibrary(mediaTypes: [.video]),
            displayTitle: L10n.continueWatchingFor(userName)
        )

        recentlyAddedMovies

        CinemaRowContentGroup(
            id: "cinema-next-up",
            library: NextUpLibrary()
        )

        if Defaults[.Customization.Home.showRecentlyAdded] {
            CinemaRowContentGroup(
                id: "cinema-recently-added-episodes",
                library: ItemLibrary(
                    parent: BaseItemDto(name: L10n.newEpisodes),
                    filters: .init(
                        itemTypes: [.episode],
                        sortBy: [.dateCreated],
                        sortOrder: [.descending]
                    )
                )
            )
        }

        CinemaRowContentGroup(
            id: CinemaTopTenStore.moviesRowID,
            library: CinemaTopTenLibrary(
                itemType: .movie,
                displayTitle: L10n.topTenMoviesOn(serverName)
            ),
            isRanked: true
        )

        CinemaRowContentGroup(
            id: "cinema-new-releases",
            library: ItemLibrary(
                parent: BaseItemDto(name: L10n.newReleases),
                filters: .init(
                    itemTypes: [.movie],
                    sortBy: [.premiereDate],
                    sortOrder: [.descending]
                )
            )
        )

        if let watched = recentlyWatched.first {
            becauseYouWatched(watched)
        }

        CinemaRowContentGroup(
            id: CinemaTopTenStore.showsRowID,
            library: CinemaTopTenLibrary(
                itemType: .series,
                displayTitle: L10n.topTenShowsOn(serverName)
            ),
            isRanked: true
        )

        CinemaRowContentGroup(
            id: "cinema-my-list",
            library: ItemLibrary(
                parent: BaseItemDto(name: L10n.myList),
                filters: .init(
                    itemTypes: [.movie, .series],
                    sortBy: [.dateCreated],
                    sortOrder: [.descending],
                    traits: [.isFavorite]
                )
            )
        )

        for category in languages.prefix(2) {
            categoryRow(category)
        }

        for category in leadingGenres {
            categoryRow(category)
        }

        CinemaRowContentGroup(
            id: "cinema-bingeworthy-shows",
            library: ItemLibrary(
                parent: BaseItemDto(name: L10n.bingeworthyTVShows),
                filters: .init(
                    itemTypes: [.series],
                    sortBy: [.communityRating],
                    sortOrder: [.descending]
                )
            )
        )

        for category in tvGenres.prefix(2) {
            categoryRow(category)
        }

        if let watched = recentlyWatched.dropFirst().first {
            becauseYouWatched(watched)
        }

        CinemaRowContentGroup(
            id: "cinema-critically-acclaimed",
            library: ItemLibrary(
                parent: BaseItemDto(name: L10n.criticallyAcclaimedMovies),
                filters: .init(
                    itemTypes: [.movie],
                    sortBy: [.criticRating],
                    sortOrder: [.descending]
                )
            )
        )

        for category in languages.dropFirst(2) {
            categoryRow(category)
        }

        for category in trailingGenres {
            categoryRow(category)
        }

        for category in tvGenres.dropFirst(2) {
            categoryRow(category)
        }

        if Defaults[.Customization.Home.showRecentlyPlayed] {
            CinemaRowContentGroup(
                id: "cinema-recently-played",
                library: ItemLibrary(
                    parent: BaseItemDto(name: L10n.watchItAgain),
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

    private func categoryRow(_ category: Category) -> any ContentGroup {
        CinemaRowContentGroup(
            id: "cinema-category-\(category.id)",
            library: ItemLibrary(
                parent: BaseItemDto(name: category.title),
                filters: category.filters
            )
        )
    }

    private func becauseYouWatched(_ title: WatchedTitle) -> any ContentGroup {
        CinemaRowContentGroup(
            id: "cinema-because-you-watched-\(title.id)",
            library: SimilarItemsLibrary(itemID: title.id, itemType: title.type),
            displayTitle: L10n.becauseYouWatched(title.name)
        )
    }

    // MARK: - Categories

    private func movieGenreCategories(from filters: QueryFilters?) -> [Category] {
        let available = genreNames(in: filters)

        return Self.movieGenrePriority
            .compactMap { available[$0.lowercased()] }
            .prefix(Limits.movieGenres)
            .map { genre in
                Category(
                    id: "movie-genre-\(genre)",
                    title: movieGenreTitle(genre),
                    filters: .init(
                        genres: [ItemGenre(stringLiteral: genre)],
                        itemTypes: [.movie],
                        sortBy: [.dateCreated],
                        sortOrder: [.descending]
                    )
                )
            }
    }

    private func tvGenreCategories(from filters: QueryFilters?) -> [Category] {
        let available = genreNames(in: filters)

        return Self.tvGenrePriority
            .compactMap { available[$0.lowercased()] }
            .prefix(Limits.tvGenres)
            .map { genre in
                Category(
                    id: "tv-genre-\(genre)",
                    title: tvGenreTitle(genre),
                    filters: .init(
                        genres: [ItemGenre(stringLiteral: genre)],
                        itemTypes: [.series],
                        sortBy: [.dateLastContentAdded],
                        sortOrder: [.descending]
                    )
                )
            }
    }

    /// Jellyfin can't filter by country, so audio language stands in for "Indian Movies" or "Made in Korea".
    /// Titles that only carry a dubbed track in a language will also appear in that language's row.
    private func languageCategories(from filters: QueryFilters?) -> [Category] {
        let languages = (filters?.audioLanguages ?? [])
            .compactMap(ItemLanguage.init)
            .reduce(into: [String: ItemLanguage]()) { $0[$1.value.lowercased()] = $1 }

        func movies(in codes: [String]) -> ItemFilterCollection {
            .init(
                audioLanguages: codes.compactMap { languages[$0] },
                itemTypes: [.movie],
                sortBy: [.dateCreated],
                sortOrder: [.descending]
            )
        }

        var categories: [Category] = []

        let indian = Self.indianLanguages.filter { languages[$0] != nil }
        let southIndian = indian.filter(Self.southIndianLanguages.contains)

        if indian.isNotEmpty {
            categories.append(.init(id: "indian-movies", title: L10n.indianMovies, filters: movies(in: indian)))
        }

        if southIndian.isNotEmpty, southIndian.count < indian.count {
            categories.append(.init(id: "south-indian-cinema", title: L10n.southIndianCinema, filters: movies(in: southIndian)))
        }

        if indian.count > 1 {
            for code in indian.prefix(Limits.indianLanguages) {
                guard let language = languages[code] else { continue }

                categories.append(.init(
                    id: "language-\(code)",
                    title: L10n.categoryMovies(language.displayTitle),
                    filters: movies(in: [code])
                ))
            }
        }

        for code in Self.worldLanguages.filter({ languages[$0] != nil }).prefix(Limits.worldLanguages) {
            guard let language = languages[code] else { continue }

            categories.append(.init(
                id: "language-\(code)",
                title: code == "kor" ? L10n.madeInKorea : L10n.categoryMovies(language.displayTitle),
                filters: movies(in: [code])
            ))
        }

        return categories
    }

    /// Server genre names keyed by lowercase name, so matching ignores case but filtering keeps the server's spelling
    private func genreNames(in filters: QueryFilters?) -> [String: String] {
        (filters?.genres ?? [])
            .compactMap(\.name)
            .reduce(into: [String: String]()) { $0[$1.lowercased()] = $1 }
    }

    private func movieGenreTitle(_ genre: String) -> String {
        switch genre.lowercased() {
        case "thriller": L10n.thrillers
        case "romance": L10n.romanticMovies
        case "science fiction": L10n.sciFiMovies
        case "animation": L10n.animatedMovies
        case "documentary": L10n.documentaries
        default: L10n.categoryMovies(genre)
        }
    }

    private func tvGenreTitle(_ genre: String) -> String {
        switch genre.lowercased() {
        case "drama": L10n.bringTheDrama
        case "comedy": L10n.tvComedies
        case "animation": L10n.animatedSeries
        case "documentary": L10n.docuseries
        case "reality": L10n.realityTV
        case "kids": L10n.kidsTV
        default: L10n.categoryTVShows(genre)
        }
    }

    // MARK: - Requests

    private func queryFilters(for itemType: BaseItemKind, userSession: UserSession) async -> QueryFilters? {
        let parameters = Paths.GetQueryFiltersParameters(
            userID: userSession.user.id,
            includeItemTypes: [itemType],
            isRecursive: true
        )

        return try? await userSession.client.send(Paths.getQueryFilters(parameters: parameters)).value
    }

    /// The most recently watched movies and series, newest first
    private func recentlyWatchedTitles(userSession: UserSession) async -> [WatchedTitle] {
        var parameters = Paths.GetItemsParameters()
        parameters.enableUserData = true
        parameters.includeItemTypes = [.movie, .episode]
        parameters.isRecursive = true
        parameters.limit = 30
        parameters.sortBy = [.datePlayed]
        parameters.sortOrder = [.descending]
        parameters.userID = userSession.user.id

        guard let items = try? await userSession.client.send(Paths.getItems(parameters: parameters)).value.items else {
            return []
        }

        var seenIDs: Set<String> = []

        return items
            .filter { $0.userData?.lastPlayedDate != nil }
            .compactMap { item -> WatchedTitle? in
                if item.type == .episode {
                    guard let seriesID = item.seriesID, let seriesName = item.seriesName else { return nil }

                    return WatchedTitle(id: seriesID, name: seriesName, type: .series)
                }

                guard let id = item.id, let name = item.name else { return nil }

                return WatchedTitle(id: id, name: name, type: item.type ?? .movie)
            }
            .filter { seenIDs.insert($0.id).inserted }
            .prefix(Limits.recentlyWatched)
            .map(\.self)
    }
}
