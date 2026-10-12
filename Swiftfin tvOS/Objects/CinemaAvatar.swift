//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

/// Illustrated character avatars a profile can pick, after Netflix's profile icons.
///
/// The choice is kept on this device by user ID, leaving the server's profile image untouched.
struct CinemaAvatar: Identifiable, Hashable {

    let id: String

    /// Asset catalog image, `Avatars/avatar-<id>`
    var imageName: String {
        "avatar-\(id)"
    }

    static let all: [CinemaAvatar] = [
        "red-panda", "fox", "tiger", "kitten",
        "penguin", "popcorn-bear", "ninja-cat", "owl-wizard",
        "astronaut", "hero", "robot", "alien",
        "dragon", "dino", "monster", "ghost",
    ]
        .map(CinemaAvatar.init(id:))

    /// Stable per user, so a profile without a picture keeps the same character between launches
    static func standard(for userID: String) -> CinemaAvatar {
        let seed = userID.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return all[seed % all.count]
    }

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

/// An avatar's artwork, filling whatever square it is given
struct CinemaAvatarTile: View {

    let avatar: CinemaAvatar

    var body: some View {
        Image(avatar.imageName)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .accessibilityHidden(true)
    }
}
