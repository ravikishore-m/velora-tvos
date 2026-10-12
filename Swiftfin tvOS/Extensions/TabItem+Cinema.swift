//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension TabItem {

    static var cinemaHome: TabItem {
        cinema(
            provider: CinemaHomeContentGroupProvider(),
            systemImage: "house.fill"
        )
    }

    static var cinemaMyList: TabItem {
        cinema(
            provider: CinemaMyListContentGroupProvider(),
            systemImage: "person.crop.square.fill"
        )
    }

    static var cinemaRequests: TabItem {
        TabItem(
            id: "cinema-requests",
            title: L10n.requests,
            systemImage: "plus.circle.fill"
        ) {
            CinemaRequestsView()
                .background {
                    CinemaTheme.Colors.background
                        .ignoresSafeArea()
                }
                .environment(\.colorScheme, .dark)
                .toolbar(.hidden, for: .navigationBar)
        }
    }

    private static func cinema(
        provider: some ContentGroupProvider,
        systemImage: String
    ) -> TabItem {
        TabItem(
            id: provider.id,
            title: provider.displayTitle,
            systemImage: systemImage
        ) {
            ContentGroupView(provider: provider)
                .background {
                    CinemaTheme.Colors.background
                        .ignoresSafeArea()
                }
                .environment(\.colorScheme, .dark)
        }
    }
}
