//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

enum CinemaTheme {

    // MARK: - Colors

    enum Colors {

        static let background = Color(red: 0.05, green: 0.05, blue: 0.06)

        static let primaryText = Color.white
        static let secondaryText = Color.white.opacity(0.72)
        static let tertiaryText = Color.white.opacity(0.5)

        static let actionBackground = Color.white.opacity(0.18)
        static let actionForeground = Color.white
        static let focusedActionBackground = Color.white
        static let focusedActionForeground = Color.black

        static let placeholder = Color.white.opacity(0.08)
    }

    // MARK: - Typography

    enum Typography {

        static let heroTitle = Font.largeTitle.weight(.bold)
        static let heroSynopsis = Font.body
        static let metadata = Font.callout.weight(.semibold)
        static let rowTitle = Font.title3.weight(.bold)
        static let action = Font.headline
    }

    // MARK: - Spacing

    enum Spacing {

        static let edge: CGFloat = EdgeInsets.edgePadding
        static let item: CGFloat = EdgeInsets.itemSpacing
        static let row: CGFloat = 50
        static let heroContent: CGFloat = 24
        static let actions: CGFloat = 24
        static let metadata: CGFloat = 16
    }

    // MARK: - Hero

    enum Hero {

        static let logoMaxWidth: CGFloat = 640
        static let logoMaxHeight: CGFloat = 200
        static let synopsisMaxWidth: CGFloat = 960
        static let synopsisLineLimit = 3
        static let backdropMaxWidth: CGFloat = 1920

        static let bottomScrim = LinearGradient(
            stops: [
                .init(color: .clear, location: 0.35),
                .init(color: Colors.background.opacity(0.75), location: 0.75),
                .init(color: Colors.background, location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )

        static let leadingScrim = LinearGradient(
            stops: [
                .init(color: Colors.background.opacity(0.85), location: 0),
                .init(color: Colors.background.opacity(0.4), location: 0.45),
                .init(color: .clear, location: 0.7),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // MARK: - Focus

    enum Focus {

        static let scale: CGFloat = 1.06
        static let pressedScale: CGFloat = 0.97
        static let cornerRadius: CGFloat = 14
        static let shadowRadius: CGFloat = 18
        static let animation: Animation = .easeOut(duration: 0.18)
        static let backdropTransition: Animation = .easeInOut(duration: 0.45)
    }
}
