//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

/// Character avatars a profile can pick, after Netflix's profile icons.
///
/// The choice is kept on this device by user ID, leaving the server's profile image untouched.
struct CinemaAvatar: Identifiable, Hashable {

    let id: String
    let character: String
    let top: Color
    let bottom: Color

    private init(_ id: String, _ character: String, _ top: (Double, Double, Double), _ bottom: (Double, Double, Double)) {
        self.id = id
        self.character = character
        self.top = Color(red: top.0, green: top.1, blue: top.2)
        self.bottom = Color(red: bottom.0, green: bottom.1, blue: bottom.2)
    }

    static let all: [CinemaAvatar] = [
        .init("fox", "🦊", (1, 0.6, 0.2), (0.85, 0.27, 0.05)),
        .init("panda", "🐼", (0.25, 0.8, 0.75), (0.05, 0.45, 0.5)),
        .init("tiger", "🐯", (1, 0.82, 0.25), (0.9, 0.45, 0.05)),
        .init("lion", "🦁", (0.98, 0.7, 0.35), (0.7, 0.35, 0.1)),
        .init("frog", "🐸", (0.55, 0.9, 0.35), (0.15, 0.55, 0.2)),
        .init("monkey", "🐵", (0.85, 0.6, 0.45), (0.5, 0.28, 0.18)),
        .init("koala", "🐨", (0.6, 0.7, 0.85), (0.3, 0.38, 0.55)),
        .init("dog", "🐶", (0.45, 0.75, 1), (0.15, 0.4, 0.85)),
        .init("cat", "🐱", (1, 0.6, 0.75), (0.85, 0.25, 0.5)),
        .init("bear", "🐻", (0.8, 0.55, 0.35), (0.45, 0.25, 0.12)),
        .init("rabbit", "🐰", (0.95, 0.85, 0.95), (0.7, 0.5, 0.8)),
        .init("penguin", "🐧", (0.4, 0.85, 0.95), (0.1, 0.35, 0.6)),
        .init("owl", "🦉", (0.75, 0.6, 0.4), (0.35, 0.25, 0.15)),
        .init("unicorn", "🦄", (0.85, 0.6, 1), (0.5, 0.25, 0.85)),
        .init("dragon", "🐉", (0.4, 0.9, 0.55), (0.05, 0.45, 0.35)),
        .init("dinosaur", "🦖", (0.6, 0.85, 0.3), (0.25, 0.5, 0.1)),
        .init("shark", "🦈", (0.35, 0.65, 0.95), (0.05, 0.2, 0.5)),
        .init("octopus", "🐙", (1, 0.5, 0.55), (0.7, 0.12, 0.3)),
        .init("alien", "👽", (0.5, 1, 0.6), (0.1, 0.5, 0.35)),
        .init("invader", "👾", (0.7, 0.45, 1), (0.3, 0.1, 0.65)),
        .init("robot", "🤖", (0.75, 0.82, 0.9), (0.35, 0.42, 0.52)),
        .init("astronaut", "🧑‍🚀", (0.25, 0.3, 0.6), (0.05, 0.05, 0.2)),
        .init("hero", "🦸", (1, 0.35, 0.3), (0.6, 0.05, 0.15)),
        .init("wizard", "🧙", (0.5, 0.4, 0.95), (0.18, 0.1, 0.5)),
        .init("ninja", "🥷", (0.4, 0.4, 0.45), (0.08, 0.08, 0.1)),
        .init("vampire", "🧛", (0.75, 0.1, 0.2), (0.25, 0.02, 0.06)),
        .init("pumpkin", "🎃", (1, 0.65, 0.2), (0.45, 0.2, 0.05)),
        .init("cool", "😎", (1, 0.85, 0.3), (0.95, 0.5, 0.1)),
    ]

    /// The avatar a user picked on this device, if any
    static func chosen(for userID: String, in choices: [String: String] = Defaults[.cinemaProfileAvatars]) -> CinemaAvatar? {
        guard let avatarID = choices[userID] else { return nil }

        return all.first { $0.id == avatarID }
    }
}

extension Defaults.Keys {

    /// Avatar IDs by user ID
    static let cinemaProfileAvatars: Key<[String: String]> = Key("cinemaProfileAvatars", default: [:], suite: .appSuite)
}

/// A character on its gradient tile, scaled to whatever size it is given
struct CinemaAvatarTile: View {

    let avatar: CinemaAvatar

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [avatar.top, avatar.bottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Text(avatar.character)
                    .font(.system(size: proxy.size.width * 0.62))
                    .shadow(color: .black.opacity(0.25), radius: proxy.size.width * 0.03, y: proxy.size.width * 0.02)
            }
        }
        .accessibilityHidden(true)
    }
}
