//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

/// The ten highest rated recent titles, topped up with all-time favourites for smaller libraries.
///
/// Jellyfin has no server-wide popularity, so ratings stand in for Netflix's daily charts.
struct CinemaTopTenLibrary: MediaLibrary {

    static let count = 10
    static let recentYears = 3

    let hasNextPage = false
    let itemType: BaseItemKind
    let parent: TitledLibraryParent

    init(itemType: BaseItemKind, displayTitle: String) {
        self.itemType = itemType
        self.parent = .init(displayTitle: displayTitle, id: "cinema-top-ten-\(itemType.rawValue)")
    }

    func retrievePage(
        environment: Empty,
        pageState: LibraryPageState
    ) async throws -> [ItemPatch] {
        let recentDate = Calendar.current.date(byAdding: .year, value: -Self.recentYears, to: .now)
        let recent = try await topRated(since: recentDate, pageState: pageState)

        guard recent.count < Self.count else { return recent }

        let recentIDs = Set(recent.compactMap(\.value.id))
        let allTime = try await topRated(since: nil, pageState: pageState)
            .filter { !recentIDs.contains($0.value.id ?? "") }

        return Array((recent + allTime).prefix(Self.count))
    }

    private func topRated(since date: Date?, pageState: LibraryPageState) async throws -> [ItemPatch] {
        var parameters = Paths.GetItemsParameters()
        parameters.enableUserData = true
        parameters.fields = PosterSubtitleField.itemFields
        parameters.includeItemTypes = [itemType]
        parameters.isRecursive = true
        parameters.limit = Self.count
        parameters.minPremiereDate = date
        parameters.sortBy = [.communityRating, .criticRating]
        parameters.sortOrder = [.descending]
        parameters.userID = pageState.userSession.user.id

        let request = Paths.getItems(parameters: parameters)
        let response = try await pageState.userSession.client.send(request)

        return try pageState.items(from: response)
    }
}

/// Item IDs currently ranked in a Top 10 row, used to badge those titles in other rows
@MainActor
final class CinemaTopTenStore: ObservableObject {

    static let shared = CinemaTopTenStore()

    @Published
    private(set) var itemIDs: Set<String> = []

    private var rankings: [String: Set<String>] = [:]

    func update(_ ids: [String], for rowID: String) {
        rankings[rowID] = Set(ids)

        let newIDs = rankings.values.reduce(into: Set<String>()) { $0.formUnion($1) }
        guard newIDs != itemIDs else { return }

        itemIDs = newIDs
    }

    func contains(_ item: BaseItemDto) -> Bool {
        if let id = item.id, itemIDs.contains(id) {
            return true
        }
        if let seriesID = item.seriesID, itemIDs.contains(seriesID) {
            return true
        }
        return false
    }
}
