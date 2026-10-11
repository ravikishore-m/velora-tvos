//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

/// Player header with logo, episode, stream formats and end time
struct CinemaPlayerTitleView: View {

    @EnvironmentObject
    private var manager: MediaPlayerManager

    let item: BaseItemDto

    /// The video plus only the selected audio track, so audio badges match what is heard
    private var streams: [MediaStream] {
        guard let playbackItem = manager.playbackItem else { return item.mediaStreams ?? [] }

        let audioStream = playbackItem.selectedAudioStreamIndex.flatMap { index in
            playbackItem.audioStreams.first { $0.index == index }
        } ?? playbackItem.audioStreams.first

        return playbackItem.videoStreams + [audioStream].compactMap(\.self)
    }

    @ViewBuilder
    private var logo: some View {
        ImageView(
            item.cinemaLogoSource(
                maxWidth: CinemaTheme.Player.logoMaxWidth,
                maxHeight: CinemaTheme.Player.logoMaxHeight
            )
        )
        .image { (image: Image) in
            image
                .aspectRatio(contentMode: .fit)
        }
        .placeholder { _ in
            EmptyView()
        }
        .failure {
            Text(item.cinemaTitle)
                .font(.title2.weight(.bold))
                .lineLimit(1)
        }
        .frame(
            maxWidth: CinemaTheme.Player.logoMaxWidth,
            maxHeight: CinemaTheme.Player.logoMaxHeight,
            alignment: .bottomLeading
        )
        .accessibilityLabel(item.cinemaTitle)
    }

    @ViewBuilder
    private var badges: some View {
        HStack(spacing: 14) {
            CinemaFormatBadges(streams: streams)

            if let officialRating = item.officialRating {
                EmptyLabel(officialRating)
                    .labelStyle(.attributeBadgeOutline)
            }

            if !item.isLiveStream {
                EndTimeLabel()
            }
        }
        .lineLimit(1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            logo

            if item.type == .episode {
                DotHStack {
                    if let seasonEpisodeLabel = item.seasonEpisodeLabel {
                        Text(seasonEpisodeLabel)
                    }

                    Text(item.displayTitle)
                }
                .font(.callout.weight(.semibold))
                .lineLimit(1)
            }

            badges
                .font(.caption.weight(.semibold))
                .foregroundStyle(CinemaTheme.Colors.secondaryText)
        }
        .foregroundStyle(CinemaTheme.Colors.primaryText)
    }
}

extension CinemaPlayerTitleView {

    /// Wall-clock time playback will finish at the current rate
    private struct EndTimeLabel: View {

        @EnvironmentObject
        private var manager: MediaPlayerManager

        var body: some View {
            TimelineView(.periodic(from: .now, by: 15)) { context in
                if let runtime = manager.item.runtime, runtime > .zero {
                    let remaining = max(runtime - manager.seconds, .zero)
                    let seconds = Double(remaining.components.seconds) / max(manager.rate, 0.1)
                    let endDate = context.date.addingTimeInterval(seconds)

                    Text(L10n.endsAtTime(endDate.formatted(date: .omitted, time: .shortened)))
                }
            }
        }
    }
}
