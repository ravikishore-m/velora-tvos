//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CoreGraphics
import JellyfinAPI

extension BaseItemDto {

    /// Series name for episodes, so the logo fallback matches the series logo
    var cinemaTitle: String {
        type == .episode ? seriesName ?? displayTitle : displayTitle
    }

    func cinemaLogoSource(maxWidth: CGFloat, maxHeight: CGFloat) -> ImageSource? {
        let environment = ImageSourceOptions(
            maxWidth: maxWidth,
            maxHeight: maxHeight
        )

        if type == .episode {
            return imageSource(
                .logo,
                itemID: parentLogoItemID,
                tag: parentLogoImageTag,
                environment: environment
            )
        }

        return imageSource(
            .logo,
            itemID: id,
            environment: environment
        )
    }

    /// Episodes use their own still; everything else prefers a text-free backdrop
    func cinemaLandscapeSources(maxWidth: CGFloat) -> [ImageSource] {
        imageSources(
            for: .landscape,
            environment: .init(
                maxWidth: maxWidth,
                viewContext: type == .episode ? .init() : .isBackdrop
            )
        )
    }
}
