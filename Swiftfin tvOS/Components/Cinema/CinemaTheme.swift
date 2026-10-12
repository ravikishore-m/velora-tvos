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

        /// A deep, warm black, so glass and artwork carry a hint of the brand red
        static let background = Color(red: 0.035, green: 0.028, blue: 0.03)

        static let primaryText = Color.white
        static let secondaryText = Color.white.opacity(0.72)
        static let tertiaryText = Color.white.opacity(0.5)

        static let track = Color.white.opacity(0.18)
        static let actionBackground = Color.white.opacity(0.18)

        static let placeholder = Color.white.opacity(0.08)
        /// Velora red, used for focus, progress and highlights
        static let accent = Color.veloraRed
        /// Warm secondary glow for backgrounds
        static let glow = Color(red: 0.6, green: 0.02, blue: 0.06)
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
        /// Clears the tab bar, which floats over the hero
        static let cardTopInset: CGFloat = 150
        static let cardCornerRadius: CGFloat = 36
        static let cardContentPadding: CGFloat = 56
        static let indicatorSpacing: CGFloat = 18
        static let indicatorHeight: CGFloat = 10

        static let chipFont = Font.callout.weight(.semibold)
        static let chipSpacing: CGFloat = 14
        static let chipPadding: CGFloat = 16
        static let chipIconSpacing: CGFloat = 12
        static let chipIconSize: CGFloat = 22
        static let maximumChipLanguages = 5

        static let logoMaxWidth: CGFloat = 620
        static let logoMaxHeight: CGFloat = 200
        static let synopsisMaxWidth: CGFloat = 920
        static let synopsisLineLimit = 2
        static let progressWidth: CGFloat = 360
        static let backdropMaxWidth: CGFloat = 1920

        static let maximumItems = 8
        static let rotationInterval: Duration = .seconds(8)
        static let crossfade: Animation = .easeInOut(duration: 0.8)
        /// The outgoing title fades out before the next fades in, so text never overlaps
        static let detailsTransition: AnyTransition = .asymmetric(
            insertion: .opacity.animation(.easeOut(duration: 0.35).delay(0.3)),
            removal: .opacity.animation(.easeIn(duration: 0.25))
        )
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

        static let bottomScrim = LinearGradient(
            stops: [
                .init(color: .clear, location: 0.5),
                .init(color: .black.opacity(0.55), location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Brand

    enum Brand {

        /// Velora red, with a deep garnet and a bright ember either side of it
        static let red = Color(red: 0.9, green: 0.04, blue: 0.08)
        static let garnet = Color(red: 0.5, green: 0.01, blue: 0.05)
        static let ember = Color(red: 1, green: 0.34, blue: 0.24)
        /// The near-black behind the launch ident
        static let night = Color(red: 0.02, green: 0.012, blue: 0.014)

        /// The mark's four faces, lit from above like a cut ruby
        static let upperLit = Color(red: 1, green: 0.24, blue: 0.22)
        static let upperShade = Color(red: 0.74, green: 0.02, blue: 0.07)
        static let lowerShade = Color(red: 0.3, green: 0, blue: 0.03)
        static let lowerLit = Color(red: 0.58, green: 0.01, blue: 0.05)
        /// Where the faces meet at the tip
        static let tip = Color(red: 1, green: 0.16, blue: 0.14)

        /// Garnet through red to ember, for progress, focus and the format glyphs
        static let gradient = LinearGradient(colors: [garnet, red, ember], startPoint: .leading, endPoint: .trailing)
        static let diagonalGradient = LinearGradient(
            colors: [red, ember],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let shimmerInterval: Duration = .seconds(7)
        static let shimmerDuration: TimeInterval = 1.2

        static let homeSize: CGFloat = 52
        static let introSize: CGFloat = 320
    }

    // MARK: - Profile

    enum Profile {

        static let size: CGFloat = 150
        static let spacing: CGFloat = 30
        static let cornerRadius: CGFloat = 12
        static let focusScale: CGFloat = 1.1
        static let focusRingWidth: CGFloat = 5
        static let panelCornerRadius: CGFloat = 48
        static let panelPadding: CGFloat = 48
        static let logoSize: CGFloat = 168
        static let titleSize: CGFloat = 52
        static let nameSize: CGFloat = 42
        static let columnWidth: CGFloat = 720
        static let nameSpacing: CGFloat = 36
        static let nameWidth: CGFloat = 420
        static let artworkRotation: Duration = .seconds(8)
        static let artworkCrossfade: Animation = .easeInOut(duration: 1.2)
        static let artworkLogoMaxWidth: CGFloat = 520
        static let artworkLogoMaxHeight: CGFloat = 180

        /// Lighter than a solid fade, since the profiles sit on a glass panel
        static let columnScrim = LinearGradient(
            stops: [
                .init(color: Brand.night.opacity(0.8), location: 0),
                .init(color: Brand.night.opacity(0.55), location: 0.4),
                .init(color: .clear, location: 0.7),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        /// The chosen profile grows as it moves to the centre
        static let chosenSize: CGFloat = 300
        static let chooseAnimation: Animation = .spring(response: 0.55, dampingFraction: 0.85)
        /// Lets the chosen profile settle before sign in begins
        static let chooseDelay: Duration = .milliseconds(550)
    }

    // MARK: - Poster Wall

    enum PosterWall {

        static let posterWidth: CGFloat = 220
        static let posterHeight: CGFloat = 330
        static let spacing: CGFloat = 24
        static let rows = 5
        static let columns = 12
        static let tilt: Angle = .degrees(-9)
        static let drift: CGFloat = 120
        static let driftDuration: TimeInterval = 40

        /// Keeps the sign-in content readable over the artwork
        static var scrim: some View {
            ZStack {
                Color.black.opacity(0.72)

                LinearGradient(
                    colors: [.black.opacity(0.6), .clear, .black.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }

    // MARK: - Avatar

    enum Avatar {

        static let size: CGFloat = 170
        static let spacing: CGFloat = 44
        static let columns = 8
        static let headerSize: CGFloat = 200
        /// Profile button at the top-leading corner of Home
        static let homeSize: CGFloat = 66
    }

    // MARK: - Player

    enum Player {

        static let logoMaxWidth: CGFloat = 520
        static let logoMaxHeight: CGFloat = 130

        /// White controls keep attention on the picture; the timeline carries the accent
        static let tint = Color.white
        static let progress = Colors.accent
        static let warning = Color.orange
    }

    // MARK: - Badge

    /// Glass format pills, each led by a Velora glyph
    enum Badge {

        static let height: CGFloat = 34
        static let cornerRadius: CGFloat = 7
        static let fontSize: CGFloat = 22
        static let glyphSize: CGFloat = 24
        static let horizontalPadding: CGFloat = 10
        static let spacing: CGFloat = 10
        /// Between the year and runtime, the content rating and the format badges
        static let groupSpacing: CGFloat = 18
        static let iconSpacing: CGFloat = 8
        static let outlineWidth: CGFloat = 2.5
        static let ratingSize: CGFloat = 26
        /// Green circle behind the content-rating check, as in the Apple TV app
        static let rating = Color(red: 0.2, green: 0.78, blue: 0.38)
        static let stackedLogoHeight: CGFloat = 44
        static let wideLogoHeight: CGFloat = 30
        static let tint = Color.white.opacity(0.92)
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

    // MARK: - Details

    enum Details {

        static let spacing: CGFloat = 16
        static let titleSpacing: CGFloat = 12
        static let actionsTopPadding: CGFloat = 12
    }

    // MARK: - Credits

    enum Credits {

        static let font = Font.callout
        static let maxWidth: CGFloat = 620
        static let castLimit = 3
        static let directorLimit = 2
        static let titleSpacing: CGFloat = 10
        static let lineSpacing: CGFloat = 6
    }

    // MARK: - Top 10

    /// Chart positions sit on the artwork in a glass tile instead of beside it
    enum TopTen {

        static let numberSize: CGFloat = 300
        static let numberTracking: CGFloat = -28
        /// How far the poster tucks over its rank number
        static let numberOverlap: CGFloat = 34
        static let outlineWidth: CGFloat = 3
        static let outlineColor = Color.white.opacity(0.7)
        static let numberFill = Colors.background

        static let badgeWidth: CGFloat = 46
        static let badgeHeight: CGFloat = 56
        static let badgeLabelSize: CGFloat = 13
        static let badgeNumberSize: CGFloat = 25
    }

    // MARK: - New Content

    enum NewContent {

        /// Titles added within this window get a "Recently added" style badge
        static let window: TimeInterval = 14 * 24 * 60 * 60
        static let fontSize: CGFloat = 16
        static let horizontalPadding: CGFloat = 14
        static let verticalPadding: CGFloat = 6
        static let cornerRadius: CGFloat = 4
        static let dotSize: CGFloat = 9
        static let inset: CGFloat = 12
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
