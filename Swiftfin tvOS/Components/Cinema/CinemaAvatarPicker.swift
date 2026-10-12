//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

/// Profile editor: pick a character avatar, go back to the original picture, or delete the profile
struct CinemaAvatarPicker: View {

    @Default(.cinemaProfileAvatars)
    private var avatarChoices

    @Environment(\.dismiss)
    private var dismiss

    let user: UserState
    let server: ServerState
    /// Offers deleting the profile when set
    let onDelete: (() -> Void)?

    private let columns = Array(
        repeating: GridItem(.fixed(CinemaTheme.Avatar.size), spacing: CinemaTheme.Avatar.spacing),
        count: CinemaTheme.Avatar.columns
    )

    private func choose(_ avatar: CinemaAvatar?) {
        avatarChoices[user.id] = avatar?.id
        dismiss()
    }

    private func delete() {
        dismiss()

        Task { @MainActor in
            // Let the cover close before the confirmation is presented from the picker
            try? await Task.sleep(for: .milliseconds(450))
            onDelete?()
        }
    }

    private var header: some View {
        HStack(spacing: 40) {
            CinemaProfilePicker.ProfileAvatar(user: user, server: server)
                .frame(width: CinemaTheme.Avatar.headerSize, height: CinemaTheme.Avatar.headerSize)

            VStack(alignment: .leading, spacing: 10) {
                Text(user.username)
                    .font(.title2.weight(.bold))

                Text(L10n.chooseAvatar)
                    .font(.title3)
                    .foregroundStyle(CinemaTheme.Colors.secondaryText)
            }

            Spacer()

            if onDelete != nil {
                Button(role: .destructive, action: delete) {
                    Label(L10n.deleteProfile, systemImage: "trash")
                }
            }
        }
        .focusSection()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 60) {
                header

                LazyVGrid(columns: columns, alignment: .leading, spacing: CinemaTheme.Avatar.spacing) {
                    Button {
                        choose(nil)
                    } label: {
                        AvatarChoice(isSelected: avatarChoices[user.id] == nil) {
                            CinemaProfilePicker.ProfileAvatar(user: user, server: server, ignoresChosenAvatar: true)
                        }
                        .accessibilityLabel(L10n.originalPicture)
                    }

                    ForEach(CinemaAvatar.all) { avatar in
                        Button {
                            choose(avatar)
                        } label: {
                            AvatarChoice(isSelected: avatarChoices[user.id] == avatar.id) {
                                CinemaAvatarTile(avatar: avatar)
                            }
                        }
                    }
                }
                .buttonStyle(.cinemaCard)
                .focusSection()
            }
            .padding(.vertical, 40)
            .edgePadding(.horizontal)
        }
        .scrollClipDisabled()
        .foregroundStyle(CinemaTheme.Colors.primaryText)
        .background {
            CinemaProfilesBackground()
        }
        .environment(\.colorScheme, .dark)
    }
}

extension CinemaAvatarPicker {

    private struct AvatarChoice<Content: View>: View {

        @Environment(\.isFocused)
        private var isFocused

        let isSelected: Bool
        @ViewBuilder
        let content: () -> Content

        private var shape: RoundedRectangle {
            RoundedRectangle(cornerRadius: CinemaTheme.Profile.cornerRadius, style: .continuous)
        }

        var body: some View {
            content()
                .frame(width: CinemaTheme.Avatar.size, height: CinemaTheme.Avatar.size)
                .clipShape(shape)
                .overlay {
                    shape
                        .strokeBorder(CinemaTheme.Brand.diagonalGradient, lineWidth: CinemaTheme.Profile.focusRingWidth)
                        .opacity(isFocused ? 1 : 0)
                }
                .overlay(alignment: .bottomTrailing) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 34, weight: .bold))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, CinemaTheme.Colors.accent)
                            .padding(8)
                    }
                }
                .scaleEffect(isFocused ? CinemaTheme.Profile.focusScale : 1)
                .shadow(color: CinemaTheme.Colors.accent.opacity(isFocused ? 0.5 : 0), radius: 24, y: 10)
                .animation(CinemaTheme.Focus.animation, value: isFocused)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
        }
    }
}
