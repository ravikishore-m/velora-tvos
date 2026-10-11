//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct CinemaBadges: View {

    let item: BaseItemDto

    var body: some View {
        HStack(spacing: CinemaTheme.Spacing.metadata) {
            ItemView.MetadataHStack(item: item)

            if let officialRating = item.officialRating {
                EmptyLabel(officialRating)
                    .labelStyle(.attributeBadgeOutline)
            }

            if let mediaStreams = item.mediaStreams {
                if mediaStreams.has4KVideo {
                    EmptyLabel("4K")
                        .labelStyle(.attributeBadgeFill)
                }

                if mediaStreams.hasDolbyVision {
                    EmptyLabel("DV")
                        .labelStyle(.attributeBadgeFill)
                } else if mediaStreams.hasHDRVideo {
                    EmptyLabel("HDR")
                        .labelStyle(.attributeBadgeFill)
                }
            }
        }
        .lineLimit(1)
        .fixedSize(horizontal: false, vertical: true)
    }
}
