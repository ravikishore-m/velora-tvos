//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import FactoryKit
import SwiftUI

/// The signed-in profile at the top of My RKPlex, like the profile card on My Netflix
struct CinemaProfileHeaderGroup: ContentGroup {

    let id = "cinema-profile-header"

    func body(with viewModel: Empty) -> some View {
        CinemaProfileHeader()
    }
}

private struct CinemaProfileHeader: View {

    @Injected(\.currentUserSession)
    private var userSession

    @InjectedObject(\.userSessionManager)
    private var userSessionManager: UserSessionManager

    @State
    private var isChoosingAvatar = false

    var body: some View {
        if let userSession {
            HStack(spacing: 40) {
                CinemaProfilePicker.ProfileAvatar(user: userSession.user, server: userSession.server)
                    .frame(width: CinemaTheme.Avatar.headerSize, height: CinemaTheme.Avatar.headerSize)

                VStack(alignment: .leading, spacing: 8) {
                    Text(userSession.user.username)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(CinemaTheme.Colors.primaryText)

                    Text(userSession.server.name)
                        .font(.callout)
                        .foregroundStyle(CinemaTheme.Colors.secondaryText)
                }

                Spacer()

                Button {
                    isChoosingAvatar = true
                } label: {
                    Label(L10n.chooseAvatar, systemImage: "face.smiling")
                }

                Button {
                    Task { @MainActor in
                        await userSessionManager.signOut(reason: .explicit)
                    }
                } label: {
                    Label(L10n.switchProfile, systemImage: "person.2")
                }
            }
            .padding(.vertical, 20)
            .edgePadding(.horizontal)
            .focusSection()
            .fullScreenCover(isPresented: $isChoosingAvatar) {
                CinemaAvatarPicker(user: userSession.user, server: userSession.server, onDelete: nil)
            }
        }
    }
}
