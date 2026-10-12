//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

/// The Velora ident, played over the whole app on every launch and every return from the background
@MainActor
final class VeloraLaunch: ObservableObject {

    static let shared = VeloraLaunch()

    /// Whether the ident is on screen
    @Published
    private(set) var isPlaying = true
    /// Whether the ident has started fading, so the screen behind can make its entrance
    @Published
    private(set) var isRevealed = false
    /// Changes on every replay, so the ident restarts from the beginning
    @Published
    private(set) var playID = 0

    func replay() {
        isRevealed = false
        isPlaying = true
        playID += 1
    }

    func reveal() {
        isRevealed = true
    }

    func finish() {
        isPlaying = false
        isRevealed = true
    }
}

struct VeloraLaunchOverlay: ViewModifier {

    @ObservedObject
    private var launch = VeloraLaunch.shared

    func body(content: Content) -> some View {
        content
            .overlay {
                if launch.isPlaying {
                    VeloraIntro(onReveal: launch.reveal, onFinished: launch.finish)
                        .id(launch.playID)
                }
            }
            .onReceive(Notifications[.applicationWillEnterForeground].publisher) {
                launch.replay()
            }
    }
}
