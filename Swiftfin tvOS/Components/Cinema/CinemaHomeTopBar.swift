//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import FactoryKit
import SwiftUI

/// The signed-in profile at the leading edge, returning to "Who's watching?", and the Velora wordmark at the trailing edge
struct CinemaHomeTopBar: View {

    @Injected(\.currentUserSession)
    private var userSession

    @InjectedObject(\.userSessionManager)
    private var userSessionManager: UserSessionManager

    var body: some View {
        HStack {
            if let userSession {
                Button {
                    Task { @MainActor in
                        await userSessionManager.signOut(reason: .explicit)
                    }
                } label: {
                    ProfileLabel(user: userSession.user, server: userSession.server)
                }
                .buttonStyle(.cinemaCard)
                .accessibilityLabel(L10n.switchProfile)
                .accessibilityValue(userSession.user.username)
            }

            Spacer()

            VeloraWordmark(size: CinemaTheme.Brand.homeSize, isShimmering: true)
        }
        .focusSection()
    }
}

extension CinemaHomeTopBar {

    private struct ProfileLabel: View {

        @Environment(\.isFocused)
        private var isFocused

        let user: UserState
        let server: ServerState

        var body: some View {
            HStack(spacing: 20) {
                CinemaProfilePicker.ProfileAvatar(user: user, server: server)
                    .frame(width: CinemaTheme.Avatar.homeSize, height: CinemaTheme.Avatar.homeSize)
                    .overlay {
                        RoundedRectangle(cornerRadius: CinemaTheme.Profile.cornerRadius, style: .continuous)
                            .strokeBorder(.white, lineWidth: isFocused ? 4 : 0)
                    }
                    .scaleEffect(isFocused ? CinemaTheme.Profile.focusScale : 1)

                if isFocused {
                    Text(L10n.switchProfile)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(CinemaTheme.Colors.primaryText)
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                }
            }
            .animation(CinemaTheme.Focus.animation, value: isFocused)
        }
    }
}
