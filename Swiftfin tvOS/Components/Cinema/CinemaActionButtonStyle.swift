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

/// Clear glass at rest; focus floods the glass with Velora violet
struct CinemaActionButtonStyle: ButtonStyle {

    @Environment(\.isEnabled)
    private var isEnabled
    @Environment(\.isFocused)
    private var isFocused

    private var isHighlighted: Bool {
        isEnabled && isFocused
    }

    private var glass: Glass {
        isHighlighted ? .regular.tint(CinemaTheme.Colors.accent).interactive() : .regular
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
            .foregroundStyle(CinemaTheme.Colors.primaryText)
            .symbolRenderingMode(.monochrome)
            .labelStyle(.titleAndIcon)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: true)
            .padding(.horizontal, 36)
            .padding(.vertical, 16)
            .glassEffect(glass, in: Capsule())
            .contentShape(Capsule())
            .scaleEffect(scale(isPressed: configuration.isPressed))
            .opacity(isEnabled ? 1 : 0.5)
            .shadow(
                color: CinemaTheme.Colors.accent.opacity(isHighlighted ? 0.5 : 0),
                radius: isHighlighted ? CinemaTheme.Focus.shadowRadius : 0,
                y: isHighlighted ? 8 : 0
            )
            .animation(CinemaTheme.Focus.animation, value: isHighlighted)
            .animation(CinemaTheme.Focus.animation, value: configuration.isPressed)
    }
}
