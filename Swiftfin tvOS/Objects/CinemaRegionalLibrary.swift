//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

/// The newest movies in a region's languages that were also made there.
///
/// Jellyfin matches a language against any audio track, so a Hollywood film with a Hindi dub would
/// count as Hindi. Production countries from the title's metadata weed those out; titles without
/// any country metadata are kept.
struct CinemaRegionalLibrary: MediaLibrary {

    static let count = 30
    /// Dubbed titles are dropped after fetching, so ask for more than are shown
    static let fetchLimit = 120

    let hasNextPage = false
    let audioLanguages: [String]
    /// Lowercased country names as they appear in production locations
    let countries: Set<String>
    let parent: TitledLibraryParent

    init(id: String, displayTitle: String, audioLanguages: [String], countries: Set<String>) {
        self.audioLanguages = audioLanguages
        self.countries = countries
        self.parent = .init(displayTitle: displayTitle, id: "cinema-regional-\(id)")
    }

    func retrievePage(
        environment: Empty,
        pageState: LibraryPageState
    ) async throws -> [ItemPatch] {
        var parameters = Paths.GetItemsParameters()
        parameters.audioLanguages = audioLanguages
        parameters.enableUserData = true
        parameters.fields = PosterSubtitleField.itemFields + [.productionLocations]
        parameters.includeItemTypes = [.movie]
        parameters.isRecursive = true
        parameters.limit = Self.fetchLimit
        parameters.sortBy = [.dateCreated]
        parameters.sortOrder = [.descending]
        parameters.userID = pageState.userSession.user.id

        let request = Paths.getItems(parameters: parameters)
        let response = try await pageState.userSession.client.send(request)

        return try pageState.items(from: response)
            .filter { isMadeInRegion($0.value.productionLocations) }
            .prefix(Self.count)
            .map(\.self)
    }

    private func isMadeInRegion(_ locations: [String]?) -> Bool {
        guard let locations, locations.isNotEmpty else { return true }

        return locations.contains { countries.contains($0.lowercased()) }
    }
}
