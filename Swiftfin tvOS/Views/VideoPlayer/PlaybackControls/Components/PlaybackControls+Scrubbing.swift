//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import SwiftUI

extension VideoPlayer.PlaybackControls {

    enum JumpDirection {
        case forward
        case backward
    }

    /// Holding right fast-forwards with the picture still playing: 2x first, then 4x
    static let fastForwardRates: [Double] = [2, 4]
    /// How long each fast-forward rate is held before stepping up to the next
    static let fastForwardStepDelay: TimeInterval = 1.5

    func startSpeedBoost() {
        guard !isSpeedBoosting, speedBoostTimer == nil else { return }

        viewState.setInteraction(.speedBoost, active: true)

        speedBoostTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [self] _ in
            // This timer is scheduled on the main actor's run loop.
            MainActor.assumeIsolated {
                isSpeedBoosting = true
                viewState.originalPlaybackRate = manager.rate

                if manager.playbackRequestStatus == .paused {
                    manager.setPlaybackRequestStatus(status: .playing)
                }

                fastForward(step: 0)
            }
        }
    }

    private func fastForward(step: Int) {
        guard isSpeedBoosting, Self.fastForwardRates.indices.contains(step) else { return }

        let rate = Self.fastForwardRates[step]
        viewState.fastForwardRate = rate
        viewState.showProgress()
        manager.setRate(rate: rate)

        toaster.present(
            Text(rate, format: .playbackRate),
            systemName: "forward.fill"
        )

        speedBoostTimer = Timer.scheduledTimer(withTimeInterval: Self.fastForwardStepDelay, repeats: false) { [self] _ in
            MainActor.assumeIsolated {
                fastForward(step: step + 1)
            }
        }
    }

    func stopSpeedBoost(performJump: Bool = false) {
        speedBoostTimer?.invalidate()
        speedBoostTimer = nil
        viewState.setInteraction(.speedBoost, active: false)
        viewState.fastForwardRate = nil

        if isSpeedBoosting {
            if let originalRate = viewState.originalPlaybackRate {
                manager.setRate(rate: originalRate)

                toaster.present(
                    Text(originalRate, format: .playbackRate),
                    systemName: "forward.fill"
                )
            }

            viewState.originalPlaybackRate = nil
            isSpeedBoosting = false
            return
        }

        if performJump {
            jumpForward()
        }
    }

    func jumpForward() {
        viewState.showProgress()
        viewState.jumpProgressObserver.jumpForward()
        toaster.present(
            Text(
                jumpForwardInterval.rawValue * viewState.jumpProgressObserver.jumps,
                format: .minuteSecondsAbbreviated
            ),
            systemName: "goforward"
        )
        scheduleJump(direction: .forward)
    }

    func jumpBackward() {
        viewState.showProgress()
        viewState.jumpProgressObserver.jumpBackward()
        toaster.present(
            Text(
                jumpBackwardInterval.rawValue * viewState.jumpProgressObserver.jumps,
                format: .minuteSecondsAbbreviated
            ),
            systemName: "gobackward"
        )
        scheduleJump(direction: .backward)
    }

    func scheduleJump(direction: JumpDirection) {
        pendingJumpWork?.cancel()

        let jumpCount = viewState.jumpProgressObserver.jumps
        let interval = direction == .forward
            ? jumpForwardInterval.rawValue
            : jumpBackwardInterval.rawValue

        let work = DispatchWorkItem { [weak manager, weak viewState] in
            let totalDuration = interval * jumpCount

            switch direction {
            case .forward:
                manager?.proxy?.jumpForward(totalDuration)
            case .backward:
                manager?.proxy?.jumpBackward(totalDuration)
            }
            viewState?.jumpProgressObserver.reset()
        }

        pendingJumpWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: work)
    }
}
