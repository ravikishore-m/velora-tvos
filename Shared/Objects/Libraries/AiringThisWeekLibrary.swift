//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

struct AiringThisWeekLibrary: BaseItemKindLibrary {

    let libraryItemTypes: [BaseItemKind] = [.episode]
    let parent: TitledLibraryParent = .init(displayTitle: L10n.airingThisWeek, id: "airing-this-week")

    func shouldRefreshForUserDataChange(environment: Empty) -> Bool {
        true
    }

    func retrievePage(
        environment: Empty,
        pageState: LibraryPageState
    ) async throws -> [ItemPatch] {
        var parameters = Paths.GetUpcomingEpisodesParameters()
        parameters.enableUserData = true
        parameters.fields = PosterSubtitleField.itemFields
        parameters.limit = pageState.pageSize
        parameters.startIndex = pageState.pageOffset
        parameters.userID = pageState.userSession.user.id

        let request = Paths.getUpcomingEpisodes(parameters: parameters)
        let response = try await pageState.userSession.client.send(request)

        return try pageState.items(from: response)
    }
}
