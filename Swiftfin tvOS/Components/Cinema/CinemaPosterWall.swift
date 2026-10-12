//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

/// Tilted, slowly drifting wall of library posters behind sign in, after the Netflix sign-in screen.
///
/// Uses the artwork remembered from the last home visit, preferring titles from `serverID`.
struct CinemaPosterWall: View {

    @Default(.cinemaFeaturedArtwork)
    private var featuredArtwork

    let serverID: String?

    @State
    private var isDrifting = false

    private var urls: [URL] {
        let fromServer = featuredArtwork.filter { $0.serverID == serverID }
        return (fromServer.isEmpty ? featuredArtwork : fromServer).map(\.wallImageURL)
    }

    private func poster(_ url: URL) -> some View {
        ImageView(ImageSource(url: url))
            .image { image in
                image.aspectRatio(contentMode: .fill)
            }
            .placeholder { _ in
                CinemaTheme.Colors.placeholder
            }
            .failure {
                CinemaTheme.Colors.placeholder
            }
            .frame(width: CinemaTheme.PosterWall.posterWidth, height: CinemaTheme.PosterWall.posterHeight)
            .clipShape(RoundedRectangle(cornerRadius: CinemaTheme.Card.cornerRadius, style: .continuous))
    }

    var body: some View {
        let urls = urls

        ZStack {
            Color.black

            if urls.isNotEmpty {
                VStack(spacing: CinemaTheme.PosterWall.spacing) {
                    ForEach(0 ..< CinemaTheme.PosterWall.rows, id: \.self) { row in
                        HStack(spacing: CinemaTheme.PosterWall.spacing) {
                            ForEach(0 ..< CinemaTheme.PosterWall.columns, id: \.self) { column in
                                poster(urls[(row * 3 + column) % urls.count])
                            }
                        }
                        .offset(x: isDrifting == row.isMultiple(of: 2) ? -CinemaTheme.PosterWall.drift : CinemaTheme.PosterWall.drift)
                    }
                }
                .rotationEffect(CinemaTheme.PosterWall.tilt)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

                CinemaTheme.PosterWall.scrim
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
        .onAppear {
            withAnimation(.linear(duration: CinemaTheme.PosterWall.driftDuration).repeatForever(autoreverses: true)) {
                isDrifting = true
            }
        }
    }
}
