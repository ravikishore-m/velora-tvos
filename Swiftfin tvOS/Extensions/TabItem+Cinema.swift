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
        let provider = CinemaHomeContentGroupProvider()

        return TabItem(
            id: provider.id,
            title: provider.displayTitle,
            systemImage: "house.fill"
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
