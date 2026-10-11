//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ButtonStyle where Self == CinemaActionButtonStyle {

    static var cinemaAction: Self {
        CinemaActionButtonStyle()
    }
}

struct CinemaActionButtonStyle: ButtonStyle {

    @Environment(\.isEnabled)
    private var isEnabled
    @Environment(\.isFocused)
    private var isFocused

    private var isHighlighted: Bool {
        isEnabled && isFocused
    }

    private var backgroundColor: Color {
        isHighlighted ? CinemaTheme.Colors.focusedActionBackground : CinemaTheme.Colors.actionBackground
    }

    private var foregroundColor: Color {
        isHighlighted ? CinemaTheme.Colors.focusedActionForeground : CinemaTheme.Colors.actionForeground
    }

    private func scale(isPressed: Bool) -> CGFloat {
        if isPressed {
            return CinemaTheme.Focus.pressedScale
        }

        return isHighlighted ? CinemaTheme.Focus.scale : 1
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(CinemaTheme.Typography.action)
            .foregroundStyle(foregroundColor)
            .symbolRenderingMode(.monochrome)
            .labelStyle(.titleAndIcon)
            .padding(.horizontal, 44)
            .padding(.vertical, 20)
            .background(
                isHighlighted ? backgroundColor : .clear,
                in: Capsule()
            )
            .glassEffect(isHighlighted ? .identity : .regular, in: Capsule())
            .contentShape(Capsule())
            .scaleEffect(scale(isPressed: configuration.isPressed))
            .opacity(isEnabled ? 1 : 0.5)
            .shadow(
                color: .black.opacity(isHighlighted ? 0.45 : 0),
                radius: isHighlighted ? CinemaTheme.Focus.shadowRadius : 0,
                y: isHighlighted ? 8 : 0
            )
            .animation(CinemaTheme.Focus.animation, value: isHighlighted)
            .animation(CinemaTheme.Focus.animation, value: configuration.isPressed)
    }
}
