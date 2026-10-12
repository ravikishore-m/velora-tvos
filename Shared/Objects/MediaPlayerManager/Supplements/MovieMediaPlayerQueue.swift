//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import Foundation
import JellyfinAPI
import SwiftUI

/// After a movie ends, play the next film Jellyfin recommends, resuming any progress from another device.
@MainActor
class MovieMediaPlayerQueue: ViewModel, MediaPlayerQueue {

    weak var manager: MediaPlayerManager? {
        didSet {
            cancellables = []
            guard let manager else { return }

            manager.$playbackItem
                .sink { [weak self] newItem in
                    self?.didReceive(newItem: newItem)
                }
                .store(in: &cancellables)
        }
    }

    let displayTitle: String = L10n.nextUp
    let id: String = "MovieMediaPlayerQueue"

    @Published
    var nextItem: MediaPlayerItemProvider?
    @Published
    var previousItem: MediaPlayerItemProvider?

    @Published
    var hasNextItem: Bool = false
    @Published
    var hasPreviousItem: Bool = false

    lazy var hasNextItemPublisher: Published<Bool>.Publisher = $hasNextItem
    lazy var hasPreviousItemPublisher: Published<Bool>.Publisher = $hasPreviousItem
    lazy var nextItemPublisher: Published<MediaPlayerItemProvider?>.Publisher = $nextItem
    lazy var previousItemPublisher: Published<MediaPlayerItemProvider?>.Publisher = $previousItem

    private var loadTask: AnyCancellable?

    var videoPlayerBody: some PlatformView {
        EmptySupplement()
    }

    private func didReceive(newItem: MediaPlayerItem?) {
        loadTask = Task {
            await MainActor.run {
                self.nextItem = nil
                self.previousItem = nil
                self.hasNextItem = false
                self.hasPreviousItem = false
            }

            try await self.loadNext(after: newItem?.baseItem)
        }
        .asAnyCancellable()
    }

    private func loadNext(after item: BaseItemDto?) async throws {
        guard let item, item.type == .movie, let itemID = item.id else { return }

        var parameters = Paths.GetSimilarItemsParameters()
        parameters.limit = 8
        parameters.userID = try authenticatedUser.id
        let response = try await send(Paths.getSimilarItems(itemID: itemID, parameters: parameters))

        let next = response.value.items?.first { candidate in
            candidate.id != itemID && candidate.type == .movie && !candidate.isMissing
        }
        guard let next, !Task.isCancelled else { return }

        let provider = MediaPlayerItemProvider(item: next) { [weak self] item, modifyItem in
            let bitrate = self?.manager?.playbackBitrate ?? Defaults[.VideoPlayer.Playback.appMaximumBitrate]
            return try await MediaPlayerItem.build(for: item, requestedBitrate: bitrate) { item in
                modifyItem?(&item)
            }
        }

        await MainActor.run {
            self.nextItem = provider
            self.hasNextItem = true
        }
    }
}

private struct EmptySupplement: PlatformView {

    var iOSView: some View {
        EmptyView()
    }

    var tvOSView: some View {
        EmptyView()
    }
}
