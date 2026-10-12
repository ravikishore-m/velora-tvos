//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import OrderedCollections
import SwiftUI

/// Netflix-style "Who's watching?" screen. Profiles cascade in, and the chosen profile glides
/// to the centre with a spinner while the others fade away.
struct CinemaProfilePicker: View {

    @Binding
    var isEditing: Bool
    @Binding
    var selectedUsers: Set<UserState>

    let userItems: [SelectUserView.UserItem]
    let servers: OrderedSet<ServerState>
    let showsServer: Bool
    let hasError: Bool
    /// Returns whether sign in started, so the picker can recover when it is cancelled or fails
    let onSelect: (UserState) async -> Bool
    let onAddUser: (ServerState) -> Void
    /// Deletes a single profile, or the selected profiles when `nil`
    let onDelete: (UserState?) -> Void

    @FocusState
    private var focusedID: String?
    @Namespace
    private var namespace

    @State
    private var hasAppeared = false
    @State
    private var chosenID: String?
    @State
    private var isPresentingServerChoice = false

    private var chosenItem: SelectUserView.UserItem? {
        userItems.first { $0.user.id == chosenID }
    }

    private var isChoosing: Bool {
        chosenID != nil
    }

    private func choose(_ item: SelectUserView.UserItem) {
        guard !isChoosing else { return }

        withAnimation(CinemaTheme.Profile.chooseAnimation) {
            chosenID = item.user.id
        }

        Task { @MainActor in
            try? await Task.sleep(for: CinemaTheme.Profile.chooseDelay)

            if await onSelect(item.user) {
                // The picker is replaced once signed in, so this only recovers from a stalled sign in
                try? await Task.sleep(for: .seconds(10))
            }

            reset()
        }
    }

    private func reset() {
        guard let chosenID else { return }

        withAnimation(CinemaTheme.Profile.chooseAnimation) {
            self.chosenID = nil
        }
        focusedID = chosenID
    }

    private func addProfile() {
        if servers.count == 1, let server = servers.first {
            onAddUser(server)
        } else {
            isPresentingServerChoice = true
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 24) {
            Text(L10n.swiftfin.uppercased())
                .font(.system(size: 48, weight: .black))
                .tracking(-1)
                .foregroundStyle(CinemaTheme.Colors.accent)

            Spacer()

            if servers.count > 1 {
                SelectUserView.ServerMenu(servers: servers)
                    .frame(width: 480, height: 66)
            }

            Menu {
                SelectUserView.AdvancedMenuContent(
                    hasUsers: userItems.isNotEmpty,
                    isEditing: $isEditing
                )
            } label: {
                Label(L10n.advanced, systemImage: "gearshape.fill")
                    .labelStyle(.iconOnly)
                    .frame(width: 66, height: 66)
            }
            .menuOrder(.fixed)
            .buttonBorderShape(.circle)
        }
        .padding(.top, 10)
        .edgePadding(.horizontal)
        .focusSection()
    }

    // MARK: - Profiles

    private var profiles: some View {
        HStack(alignment: .top, spacing: CinemaTheme.Profile.spacing) {
            ForEach(Array(userItems.enumerated()), id: \.element.user.id) { index, item in
                profileButton(item)
                    .modifier(EntranceModifier(index: index, isVisible: hasAppeared))
            }

            if !isEditing {
                Button(action: addProfile) {
                    AddProfileLabel()
                }
                .buttonStyle(.cinemaCard)
                .modifier(EntranceModifier(index: userItems.count, isVisible: hasAppeared))
                .opacity(isChoosing ? 0 : 1)
                .scaleEffect(isChoosing ? 0.85 : 1)
                .transition(.opacity.combined(with: .scale(scale: 0.85)))
            }
        }
        .padding(.vertical, 40)
        .edgePadding(.horizontal)
        .frame(maxWidth: .infinity)
        .scrollIfLargerThanContainer(axes: .horizontal)
        .scrollClipDisabled()
        .focusSection()
        .animation(CinemaTheme.Profile.chooseAnimation, value: isEditing)
    }

    @ViewBuilder
    private func profileButton(_ item: SelectUserView.UserItem) -> some View {
        let isChosen = item.user.id == chosenID
        let isSelected = selectedUsers.contains(item.user)

        Button {
            if isEditing {
                selectedUsers.toggle(value: item.user)
            } else {
                choose(item)
            }
        } label: {
            ProfileLabel(
                user: item.user,
                server: item.server,
                showsServer: showsServer,
                isEditing: isEditing,
                isSelected: isSelected,
                isHidden: isChosen,
                namespace: namespace
            )
        }
        .buttonStyle(.cinemaCard)
        .focused($focusedID, equals: item.user.id)
        .contextMenu {
            if !isEditing {
                Button(L10n.delete, role: .destructive) {
                    onDelete(item.user)
                }
            }
        }
        .opacity(isChoosing && !isChosen ? 0 : 1)
        .scaleEffect(isChoosing && !isChosen ? 0.85 : 1)
    }

    // MARK: - Footer

    @ViewBuilder
    private var footer: some View {
        HStack(spacing: 32) {
            if isEditing {
                Button(L10n.done) {
                    isEditing = false
                }
                .buttonStyle(OutlineButtonStyle())

                Button {
                    onDelete(nil)
                } label: {
                    Label(L10n.delete, systemImage: "trash")
                }
                .buttonStyle(OutlineButtonStyle(isDestructive: true))
                .disabled(selectedUsers.isEmpty)
            } else {
                Button {
                    isEditing = true
                } label: {
                    Label(L10n.manageProfiles, systemImage: "pencil")
                }
                .buttonStyle(OutlineButtonStyle())
            }
        }
        .focusSection()
    }

    // MARK: - Chosen

    @ViewBuilder
    private var chosenOverlay: some View {
        if let chosenItem {
            VStack(spacing: 56) {
                ProfileAvatar(user: chosenItem.user, server: chosenItem.server)
                    .matchedGeometryEffect(id: chosenItem.user.id, in: namespace)
                    .frame(width: CinemaTheme.Profile.chosenSize, height: CinemaTheme.Profile.chosenSize)
                    .shadow(color: CinemaTheme.Colors.accent.opacity(0.45), radius: 60)

                Spinner()
                    .transition(.opacity.animation(.easeIn(duration: 0.3).delay(0.35)))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(false)
        }
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                header
                    .opacity(isChoosing ? 0 : 1)

                Spacer(minLength: 0)

                Text(isEditing ? L10n.manageProfiles : L10n.whosWatching)
                    .font(.system(size: 64, weight: .bold))
                    .foregroundStyle(.white)
                    .contentTransition(.opacity)
                    .accessibilityAddTraits(.isHeader)
                    .modifier(EntranceModifier(index: -1, isVisible: hasAppeared))
                    .opacity(isChoosing ? 0 : 1)

                profiles
                    .padding(.top, 40)

                footer
                    .padding(.top, 40)
                    .modifier(EntranceModifier(index: userItems.count + 1, isVisible: hasAppeared))
                    .opacity(isChoosing ? 0 : 1)

                Spacer(minLength: 0)
            }

            chosenOverlay
        }
        .disabled(isChoosing)
        .defaultFocus($focusedID, userItems.first?.user.id, priority: .userInitiated)
        .onAppear {
            hasAppeared = true
        }
        .onChange(of: hasError) {
            if hasError {
                reset()
            }
        }
        .confirmationDialog(L10n.addUser, isPresented: $isPresentingServerChoice) {
            ForEach(servers) { server in
                Button(server.name) {
                    onAddUser(server)
                }
            }
        }
    }
}

// MARK: - Background

/// Deep red glow with faint concentric rings, after the Netflix profile screen
struct CinemaProfilesBackground: View {

    @State
    private var isGlowing = false

    var body: some View {
        ZStack {
            Color.black

            RadialGradient(
                colors: [
                    Color(red: 0.42, green: 0.05, blue: 0.07),
                    Color(red: 0.2, green: 0.02, blue: 0.04),
                    .black,
                ],
                center: UnitPoint(x: 0.5, y: -0.2),
                startRadius: 0,
                endRadius: 1500
            )
            .opacity(isGlowing ? 1 : 0.75)

            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: -size.height * 0.15)

                for index in 1 ... 16 {
                    let radius = CGFloat(index) * 140
                    let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)

                    context.stroke(
                        Path(ellipseIn: rect),
                        with: .color(.white.opacity(0.03)),
                        lineWidth: 1.5
                    )
                }
            }

            LinearGradient(
                colors: [.clear, .black.opacity(0.85)],
                startPoint: .center,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
        .onAppear {
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                isGlowing = true
            }
        }
    }
}

// MARK: - Components

extension CinemaProfilePicker {

    /// Cascades content in on first appearance, ordered by `index`
    private struct EntranceModifier: ViewModifier {

        let index: Int
        let isVisible: Bool

        func body(content: Content) -> some View {
            content
                .opacity(isVisible ? 1 : 0)
                .scaleEffect(isVisible ? 1 : 0.86)
                .offset(y: isVisible ? 0 : 40)
                .animation(
                    .spring(response: 0.6, dampingFraction: 0.8)
                        .delay(0.2 + Double(index + 1) * 0.07),
                    value: isVisible
                )
        }
    }

    struct ProfileAvatar: View {

        let user: UserState
        let server: ServerState

        /// Stable per user so a profile keeps its colour between launches
        private var tileColor: Color {
            let palette = CinemaTheme.Profile.palette
            let seed = user.id.unicodeScalars.reduce(0) { $0 + Int($1.value) }

            return palette[seed % palette.count]
        }

        private var initial: String {
            user.username.first.map { String($0).uppercased() } ?? ""
        }

        var body: some View {
            ZStack {
                LinearGradient(
                    colors: [tileColor, tileColor.mix(with: .black, by: 0.35)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Text(initial)
                    .font(.system(size: 110, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.5)

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
            .clipShape(RoundedRectangle(cornerRadius: CinemaTheme.Profile.cornerRadius, style: .continuous))
        }
    }

    private struct ProfileLabel: View {

        @Environment(\.isFocused)
        private var isFocused

        let user: UserState
        let server: ServerState
        let showsServer: Bool
        let isEditing: Bool
        let isSelected: Bool
        /// The avatar is drawn in the centre while this profile signs in
        let isHidden: Bool
        let namespace: Namespace.ID

        private var shape: RoundedRectangle {
            RoundedRectangle(cornerRadius: CinemaTheme.Profile.cornerRadius, style: .continuous)
        }

        @ViewBuilder
        private var avatar: some View {
            if isHidden {
                Color.clear
            } else {
                ProfileAvatar(user: user, server: server)
                    .matchedGeometryEffect(id: user.id, in: namespace)
            }
        }

        var body: some View {
            VStack(spacing: 24) {
                avatar
                    .frame(width: CinemaTheme.Profile.size, height: CinemaTheme.Profile.size)
                    .overlay {
                        if isEditing, !isHidden {
                            ZStack {
                                shape.fill(.black.opacity(isSelected ? 0.3 : 0.5))

                                Image(systemName: isSelected ? "checkmark.circle.fill" : "pencil")
                                    .font(.system(size: 64, weight: .semibold))
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, CinemaTheme.Colors.accent)
                            }
                        }
                    }
                    .overlay {
                        shape.strokeBorder(.white, lineWidth: isFocused && !isHidden ? 6 : 0)
                    }
                    .scaleEffect(isFocused ? CinemaTheme.Profile.focusScale : 1)
                    .shadow(
                        color: .black.opacity(isFocused ? 0.6 : 0.3),
                        radius: isFocused ? 30 : 10,
                        y: isFocused ? 16 : 6
                    )

                VStack(spacing: 6) {
                    Text(user.username)
                        .font(.title3.weight(isFocused ? .semibold : .regular))
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
                .opacity(isHidden ? 0 : 1)
            }
            .animation(CinemaTheme.Focus.animation, value: isFocused)
            .accessibilityElement(children: .combine)
        }
    }

    private struct AddProfileLabel: View {

        @Environment(\.isFocused)
        private var isFocused

        private var shape: RoundedRectangle {
            RoundedRectangle(cornerRadius: CinemaTheme.Profile.cornerRadius, style: .continuous)
        }

        var body: some View {
            VStack(spacing: 24) {
                ZStack {
                    shape.fill(.white.opacity(isFocused ? 0.2 : 0.08))

                    Image(systemName: "plus")
                        .font(.system(size: 90, weight: .light))
                        .foregroundStyle(.white.opacity(isFocused ? 1 : 0.7))
                }
                .frame(width: CinemaTheme.Profile.size, height: CinemaTheme.Profile.size)
                .overlay {
                    shape.strokeBorder(.white, lineWidth: isFocused ? 6 : 0)
                }
                .scaleEffect(isFocused ? CinemaTheme.Profile.focusScale : 1)

                Text(L10n.addProfile)
                    .font(.title3.weight(isFocused ? .semibold : .regular))
                    .foregroundStyle(isFocused ? CinemaTheme.Colors.primaryText : CinemaTheme.Colors.tertiaryText)
                    .lineLimit(1)
                    .frame(width: CinemaTheme.Profile.size)
            }
            .animation(CinemaTheme.Focus.animation, value: isFocused)
            .accessibilityElement(children: .combine)
        }
    }

    /// Thin outlined capsule that fills white on focus, like the Manage Profiles button
    private struct OutlineButtonStyle: ButtonStyle {

        var isDestructive = false

        func makeBody(configuration: Configuration) -> some View {
            OutlineButtonLabel(configuration: configuration, isDestructive: isDestructive)
        }
    }

    private struct OutlineButtonLabel: View {

        @Environment(\.isFocused)
        private var isFocused
        @Environment(\.isEnabled)
        private var isEnabled

        let configuration: ButtonStyleConfiguration
        let isDestructive: Bool

        private var fill: Color {
            guard isFocused else { return .clear }

            return isDestructive ? CinemaTheme.Colors.accent : .white
        }

        private var foreground: Color {
            isFocused && !isDestructive ? .black : .white
        }

        var body: some View {
            configuration.label
                .font(.headline)
                .foregroundStyle(foreground)
                .padding(.horizontal, 40)
                .padding(.vertical, 18)
                .background(Capsule().fill(fill))
                .overlay {
                    Capsule().strokeBorder(.white.opacity(isFocused ? 0 : 0.55), lineWidth: 2)
                }
                .scaleEffect(configuration.isPressed ? CinemaTheme.Focus.pressedScale : isFocused ? 1.06 : 1)
                .opacity(isEnabled ? 1 : 0.4)
                .animation(CinemaTheme.Focus.animation, value: isFocused)
                .animation(CinemaTheme.Focus.animation, value: configuration.isPressed)
        }
    }

    /// Accent ring spinner shown while the chosen profile signs in
    private struct Spinner: View {

        @State
        private var isRotating = false

        var body: some View {
            Circle()
                .trim(from: 0.05, to: 0.8)
                .stroke(CinemaTheme.Colors.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 84, height: 84)
                .rotationEffect(.degrees(isRotating ? 360 : 0))
                .onAppear {
                    withAnimation(.linear(duration: 0.9).repeatForever(autoreverses: false)) {
                        isRotating = true
                    }
                }
                .accessibilityHidden(true)
        }
    }
}
