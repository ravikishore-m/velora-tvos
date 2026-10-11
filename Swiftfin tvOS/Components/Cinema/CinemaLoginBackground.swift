//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

/// Server artwork under a dark scrim with slowly drifting accent glows
struct CinemaLoginBackground<Artwork: View>: View {

    @State
    private var isDrifting = false

    private let artwork: Artwork

    init(@ViewBuilder artwork: () -> Artwork) {
        self.artwork = artwork()
    }

    var body: some View {
        ZStack {
            CinemaTheme.Colors.background

            artwork
                .opacity(0.45)

            LinearGradient(
                stops: [
                    .init(color: CinemaTheme.Colors.background.opacity(0.55), location: 0),
                    .init(color: CinemaTheme.Colors.background.opacity(0.92), location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [CinemaTheme.Colors.accent.opacity(0.35), .clear],
                center: isDrifting ? UnitPoint(x: 0.15, y: 0.95) : UnitPoint(x: 0.3, y: 1.1),
                startRadius: 0,
                endRadius: 900
            )
            .blendMode(.screen)

            RadialGradient(
                colors: [CinemaTheme.Colors.glow.opacity(0.25), .clear],
                center: isDrifting ? UnitPoint(x: 0.9, y: 0.05) : UnitPoint(x: 0.75, y: -0.1),
                startRadius: 0,
                endRadius: 800
            )
            .blendMode(.screen)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
        .onAppear {
            withAnimation(.easeInOut(duration: 12).repeatForever(autoreverses: true)) {
                isDrifting = true
            }
        }
    }
}

extension CinemaLoginBackground where Artwork == EmptyView {

    init() {
        self.init {
            EmptyView()
        }
    }
}
