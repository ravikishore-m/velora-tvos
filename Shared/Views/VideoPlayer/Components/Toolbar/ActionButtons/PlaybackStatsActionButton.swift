//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

#if os(tvOS)
extension VideoPlayer.PlaybackControls.Toolbar.ActionButtons {

    struct PlaybackStats: View {

        @Environment(ViewState.self)
        private var viewState

        var body: some View {
            Button(
                L10n.playbackInfo,
                systemImage: VideoPlayerActionButton.playbackStats.systemImage
            ) {
                viewState.isShowingPlaybackStats.toggle()
            }
        }
    }
}
#endif
