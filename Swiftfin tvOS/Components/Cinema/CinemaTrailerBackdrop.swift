//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import AVFoundation
import Defaults
import JellyfinAPI
import SwiftUI

/// Fades a local trailer in over the backdrop after the header has been focused for a moment, as Netflix does
struct CinemaTrailerBackdrop: View {

    private struct TaskID: Equatable {
        let trailerID: String?
        let isActive: Bool
        let isEnabled: Bool
    }

    @Default(.Customization.shouldAutoplayTrailers)
    private var shouldAutoplayTrailers

    @State
    private var player: AVPlayer?
    @State
    private var isVisible = false

    let trailer: BaseItemDto?
    let isActive: Bool

    private static let startDelay: Duration = .seconds(3)
    private static let readyTimeout: Duration = .seconds(15)

    private func stop() {
        withAnimation(.easeInOut(duration: 0.8)) {
            isVisible = false
        }
        player?.pause()
    }

    private func waitUntilPlaying(_ player: AVPlayer) async -> Bool {
        let deadline = ContinuousClock.now + Self.readyTimeout

        while ContinuousClock.now < deadline, !Task.isCancelled {
            if player.timeControlStatus == .playing, player.currentTime().seconds > 0.2 {
                return true
            }
            if player.currentItem?.status == .failed {
                return false
            }
            try? await Task.sleep(for: .milliseconds(200))
        }

        return false
    }

    private func play(_ trailer: BaseItemDto) async {
        try? await Task.sleep(for: Self.startDelay)
        guard !Task.isCancelled,
              let provider = trailer.getPlaybackItemProvider(userSession: nil),
              let playbackItem = try? await provider(),
              !Task.isCancelled
        else { return }

        let player = AVPlayer(url: playbackItem.url)
        player.allowsExternalPlayback = false
        self.player = player
        player.play()

        guard await waitUntilPlaying(player) else {
            player.pause()
            return
        }

        withAnimation(.easeInOut(duration: 1.2)) {
            isVisible = true
        }

        if let currentItem = player.currentItem {
            for await _ in NotificationCenter.default.notifications(named: AVPlayerItem.didPlayToEndTimeNotification, object: currentItem) {
                break
            }
        }

        stop()
    }

    var body: some View {
        ZStack {
            if let player {
                PlayerLayerView(player: player)
                    .overlay {
                        LinearGradient(
                            stops: [
                                .init(color: .black.opacity(0.8), location: 0),
                                .init(color: .black.opacity(0.25), location: 0.55),
                                .init(color: .clear, location: 1),
                            ],
                            startPoint: .bottomLeading,
                            endPoint: .topTrailing
                        )
                    }
                    .opacity(isVisible ? 1 : 0)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task(id: TaskID(trailerID: trailer?.id, isActive: isActive, isEnabled: shouldAutoplayTrailers)) {
            guard shouldAutoplayTrailers, isActive, let trailer else {
                stop()
                return
            }

            await play(trailer)
        }
        .onDisappear {
            stop()
            player = nil
        }
    }
}

extension CinemaTrailerBackdrop {

    private struct PlayerLayerView: UIViewRepresentable {

        let player: AVPlayer

        func makeUIView(context: Context) -> PlayerUIView {
            PlayerUIView(player: player)
        }

        func updateUIView(_ uiView: PlayerUIView, context: Context) {
            uiView.playerLayer.player = player
        }
    }

    private final class PlayerUIView: UIView {

        override static var layerClass: AnyClass {
            AVPlayerLayer.self
        }

        var playerLayer: AVPlayerLayer {
            // swiftlint:disable:next force_cast
            layer as! AVPlayerLayer
        }

        init(player: AVPlayer) {
            super.init(frame: .zero)
            playerLayer.player = player
            playerLayer.videoGravity = .resizeAspectFill
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
