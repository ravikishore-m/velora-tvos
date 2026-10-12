//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import FactoryKit
import Foundation
import JellyfinAPI

/// Artwork from the last home hero, so the profile picker can show the library before anyone signs in.
///
/// Only public image URLs and display text are kept; Jellyfin serves item images without authentication.
struct CinemaFeaturedArtwork: Storable, Hashable {

    static let maximumCount = 8

    let serverID: String
    let title: String
    let genres: [String]
    let backdropURL: URL
    let logoURL: URL?
    var posterURL: URL?

    /// Portrait artwork for poster walls, falling back to the backdrop for entries saved before posters were kept
    var wallImageURL: URL {
        posterURL ?? backdropURL
    }

    @MainActor
    static func remember(_ items: [BaseItemDto]) {
        guard let serverID = Container.shared.currentUserSession()?.server.id else { return }

        let artwork: [CinemaFeaturedArtwork] = items
            .prefix(maximumCount)
            .compactMap { item in
                guard let backdropURL = item.cinemaLandscapeSources(maxWidth: CinemaTheme.Hero.backdropMaxWidth)
                    .first?
                    .url
                    .flatMap(withoutCredentials)
                else { return nil }

                return CinemaFeaturedArtwork(
                    serverID: serverID,
                    title: item.cinemaTitle,
                    genres: Array((item.genres ?? []).prefix(3)),
                    backdropURL: backdropURL,
                    logoURL: item.cinemaLogoSource(
                        maxWidth: CinemaTheme.Hero.logoMaxWidth,
                        maxHeight: CinemaTheme.Hero.logoMaxHeight
                    )?
                        .url
                        .flatMap(withoutCredentials),
                    posterURL: item.cinemaPosterSource(maxWidth: CinemaTheme.Card.portraitWidth)?
                        .url
                        .flatMap(withoutCredentials)
                )
            }

        guard artwork.isNotEmpty, artwork != Defaults[.cinemaFeaturedArtwork] else { return }

        Defaults[.cinemaFeaturedArtwork] = artwork
    }

    /// Never persists an access token, should a URL ever carry one
    private static func withoutCredentials(_ url: URL) -> URL? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }

        components.queryItems = components.queryItems?.filter { item in
            !["api_key", "apikey", "token", "accesstoken"].contains(item.name.lowercased())
        }

        return components.url
    }
}

extension Defaults.Keys {

    static let cinemaFeaturedArtwork: Key<[CinemaFeaturedArtwork]> = Key("cinemaFeaturedArtwork", default: [], suite: .appSuite)
}

extension BaseItemDto {

    /// Distinct audio track languages, such as ["tel", "tam", "hin"]
    var cinemaAudioLanguageCodes: [String] {
        var seen: Set<String> = []

        return (mediaStreams ?? [])
            .filter { $0.type == .audio }
            .compactMap { $0.language?.lowercased() }
            .filter { $0.isNotEmpty && $0 != "und" && seen.insert($0).inserted }
    }
}
