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
        /// Netflix red, used for progress and highlights
        static let accent = Color(red: 0.898, green: 0.035, blue: 0.078)
        /// Cool secondary glow for backgrounds
        static let glow = Color(red: 0.25, green: 0.4, blue: 1)
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

        /// Fraction of the visible height used by the hero, leaving the first row peeking below
        static let heightRatio: CGFloat = 0.84
        static let minimumHeight: CGFloat = 700
        static let contentBottomPadding: CGFloat = 36
        static let logoMaxWidth: CGFloat = 620
        static let logoMaxHeight: CGFloat = 200
        static let synopsisMaxWidth: CGFloat = 900
        static let synopsisLineLimit = 3
        static let progressWidth: CGFloat = 360
        static let backdropMaxWidth: CGFloat = 1920
        static let backdropFadeStart: CGFloat = 0.6

        static let maximumItems = 8
        static let rotationInterval: Duration = .seconds(8)
        static let crossfade: Animation = .easeInOut(duration: 0.8)
        static let zoomScale: CGFloat = 1.08
        static let zoomDuration: TimeInterval = 20

        static let leadingScrim = LinearGradient(
            stops: [
                .init(color: Colors.background.opacity(0.92), location: 0),
                .init(color: Colors.background.opacity(0.55), location: 0.4),
                .init(color: .clear, location: 0.72),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // MARK: - Profile

    enum Profile {

        static let size: CGFloat = 230
        static let spacing: CGFloat = 60
        static let cornerRadius: CGFloat = 12
        static let focusScale: CGFloat = 1.1
        /// The chosen profile grows as it moves to the centre
        static let chosenSize: CGFloat = 300
        static let chooseAnimation: Animation = .spring(response: 0.55, dampingFraction: 0.85)
        /// Lets the chosen profile settle before sign in begins
        static let chooseDelay: Duration = .milliseconds(550)

        static let palette: [Color] = [
            Color(red: 0.13, green: 0.47, blue: 0.95),
            Color(red: 0.96, green: 0.74, blue: 0.1),
            Color(red: 0.9, green: 0.04, blue: 0.08),
            Color(red: 0.11, green: 0.68, blue: 0.4),
            Color(red: 0.55, green: 0.3, blue: 0.9),
            Color(red: 0.96, green: 0.45, blue: 0.1),
        ]
    }

    // MARK: - Player

    enum Player {

        static let logoMaxWidth: CGFloat = 520
        static let logoMaxHeight: CGFloat = 130

        /// Apple TV style: white controls rather than the brand accent
        static let tint = Color.white
        static let warning = Color.orange
    }

    // MARK: - Badge

    enum Badge {

        static let height: CGFloat = 30
        static let cornerRadius: CGFloat = 6
        static let fontSize: CGFloat = 19
        static let horizontalPadding: CGFloat = 8
        static let spacing: CGFloat = 12
        /// Between the year and runtime, ratings, age rating and format badges
        static let groupSpacing: CGFloat = 22
        static let iconSpacing: CGFloat = 6
        static let outlineWidth: CGFloat = 2
        static let star = Color(red: 1, green: 0.8, blue: 0.2)
        static let stackedLogoHeight: CGFloat = 38
        static let wideLogoHeight: CGFloat = 28
        static let tint = Color.white.opacity(0.85)
    }

    // MARK: - Card

    enum Card {

        static let height: CGFloat = 360
        static let portraitWidth: CGFloat = 240
        /// 16:9 billboard shown while a card has focus
        static let expandedWidth: CGFloat = 640
        static let spacing: CGFloat = 24
        static let cornerRadius: CGFloat = 12
        static let contentPadding: CGFloat = 24
        static let contentSpacing: CGFloat = 10
        static let logoMaxWidth: CGFloat = 360
        static let logoMaxHeight: CGFloat = 90
        static let synopsisLineLimit = 2
        static let progressHeight: CGFloat = 6
        static let imageMaxWidth: CGFloat = 640
        static let headerSpacing: CGFloat = 20

        static let expandAnimation: Animation = .spring(response: 0.38, dampingFraction: 0.86)

        static let scrim = LinearGradient(
            stops: [
                .init(color: .clear, location: 0.2),
                .init(color: Colors.background.opacity(0.65), location: 0.55),
                .init(color: Colors.background.opacity(0.95), location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Top 10

    enum TopTen {

        static let numberSize: CGFloat = 300
        static let numberTracking: CGFloat = -28
        /// How far each poster tucks over its rank number
        static let numberOverlap: CGFloat = 34
        static let outlineWidth: CGFloat = 3
        static let outlineColor = Color.white.opacity(0.7)
        static let numberFill = Colors.background

        static let badgeWidth: CGFloat = 46
        static let badgeHeight: CGFloat = 56
        static let badgeLabelSize: CGFloat = 13
        static let badgeNumberSize: CGFloat = 25
        static let inlineBadgeScale: CGFloat = 0.62
    }

    // MARK: - New Content

    enum NewContent {

        /// Titles added within this window get a "Recently added" style badge
        static let window: TimeInterval = 14 * 24 * 60 * 60
        static let fontSize: CGFloat = 17
        static let horizontalPadding: CGFloat = 12
        static let verticalPadding: CGFloat = 5
        static let cornerRadius: CGFloat = 4
    }

    // MARK: - Focus

    enum Focus {

        static let scale: CGFloat = 1.06
        static let pressedScale: CGFloat = 0.97
        static let cornerRadius: CGFloat = 14
        static let shadowRadius: CGFloat = 18
        static let animation: Animation = .spring(response: 0.3, dampingFraction: 0.75)
        static let backdropTransition: Animation = .easeInOut(duration: 0.45)
    }
}
