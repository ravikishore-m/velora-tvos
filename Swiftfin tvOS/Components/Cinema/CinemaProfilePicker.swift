//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

/// Netflix-style row of large square profile tiles
struct CinemaProfilePicker: View {

    @Binding
    var isEditing: Bool
    @Binding
    var selectedUsers: Set<UserState>

    let userItems: [SelectUserView.UserItem]
    let showsServer: Bool
    let action: (UserState) -> Void
    let onDelete: (UserState) -> Void

    var body: some View {
        HStack(spacing: CinemaTheme.Profile.spacing) {
            ForEach(userItems, id: \.user.id) { item in
                ProfileButton(
                    user: item.user,
                    server: item.server,
                    showsServer: showsServer,
                    isEditing: isEditing,
                    isSelected: selectedUsers.contains(item.user)
                ) {
                    if isEditing {
                        selectedUsers.toggle(value: item.user)
                    } else {
                        action(item.user)
                    }
                } onDelete: {
                    onDelete(item.user)
                }
            }
        }
        .padding(.vertical, 40)
        .edgePadding(.horizontal)
        .focusSection()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .scrollIfLargerThanContainer(axes: .horizontal)
        .scrollClipDisabled()
    }
}

extension CinemaProfilePicker {

    private struct ProfileButton: View {

        let user: UserState
        let server: ServerState
        let showsServer: Bool
        let isEditing: Bool
        let isSelected: Bool
        let action: () -> Void
        let onDelete: () -> Void

        var body: some View {
            Button(action: action) {
                ProfileLabel(
                    user: user,
                    server: server,
                    showsServer: showsServer,
                    isDimmed: isEditing && !isSelected,
                    showsCheckmark: isEditing && isSelected
                )
            }
            .buttonStyle(.cinemaCard)
            .contextMenu {
                if !isEditing {
                    Button(L10n.delete, role: .destructive, action: onDelete)
                }
            }
        }
    }

    private struct ProfileLabel: View {

        @Environment(\.isFocused)
        private var isFocused

        let user: UserState
        let server: ServerState
        let showsServer: Bool
        let isDimmed: Bool
        let showsCheckmark: Bool

        private var shape: RoundedRectangle {
            RoundedRectangle(cornerRadius: CinemaTheme.Profile.cornerRadius, style: .continuous)
        }

        /// Stable per user so a profile keeps its colour between launches
        private var tileColor: Color {
            let palette = CinemaTheme.Profile.palette
            let seed = user.id.unicodeScalars.reduce(0) { $0 + Int($1.value) }

            return palette[seed % palette.count]
        }

        private var initial: String {
            user.username.first.map { String($0).uppercased() } ?? ""
        }

        @ViewBuilder
        private var tile: some View {
            ZStack {
                tileColor

                Text(initial)
                    .font(.system(size: 110, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                ImageView(user.profileImageSource(client: server.client))
                    .pipeline(.Swiftfin.local)
                    .image { image in
                        image.aspectRatio(contentMode: .fill)
                    }
                    .placeholder { _ in
                        Color.clear
                    }
                    .failure {
                        Color.clear
                    }
            }
            .frame(width: CinemaTheme.Profile.size, height: CinemaTheme.Profile.size)
            .clipShape(shape)
            .overlay {
                shape
                    .fill(Color.black.opacity(isDimmed ? 0.55 : 0))
            }
            .overlay {
                shape
                    .strokeBorder(.white, lineWidth: isFocused ? 6 : 0)
            }
            .overlay(alignment: .bottomTrailing) {
                if showsCheckmark {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 56))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, CinemaTheme.Colors.accent)
                        .padding(12)
                }
            }
            .scaleEffect(isFocused ? CinemaTheme.Profile.focusScale : 1)
            .shadow(color: .black.opacity(isFocused ? 0.6 : 0.3), radius: isFocused ? 24 : 8, y: isFocused ? 14 : 4)
        }

        var body: some View {
            VStack(spacing: 28) {
                tile

                VStack(spacing: 6) {
                    Text(user.username)
                        .font(.title3.weight(isFocused ? .bold : .medium))
                        .foregroundStyle(isFocused ? CinemaTheme.Colors.primaryText : CinemaTheme.Colors.tertiaryText)
                        .lineLimit(1)

                    if showsServer {
                        Text(server.name)
                            .font(.footnote)
                            .foregroundStyle(CinemaTheme.Colors.tertiaryText)
                            .lineLimit(1)
                    }
                }
                .frame(width: CinemaTheme.Profile.size)
            }
            .animation(CinemaTheme.Focus.animation, value: isFocused)
            .accessibilityElement(children: .combine)
        }
    }
}
