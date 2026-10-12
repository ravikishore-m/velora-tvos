//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

/// Addresses for Seerr, Sonarr and Radarr. The file that fills this in stays out of git.
struct RequestServicesConfiguration: Decodable, Sendable {

    let seerrURL: URL
    let seerrAPIKey: String
    let sonarrURL: URL
    let sonarrAPIKey: String
    let radarrURL: URL
    let radarrAPIKey: String

    static let current: RequestServicesConfiguration? = load()

    private static func load() -> RequestServicesConfiguration? {
        guard let url = Bundle.main.url(forResource: "RequestServices", withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else { return nil }

        return try? JSONDecoder().decode(RequestServicesConfiguration.self, from: data)
    }
}

struct RequestTitle: Identifiable, Hashable, Sendable {

    var id: String {
        "\(mediaType)-\(tmdbID)"
    }

    let tmdbID: Int
    let mediaType: String
    let title: String
    let year: String?
    let posterURL: URL?
}

struct OpenRequest: Identifiable, Hashable, Sendable {

    let id: Int
    let memoryKey: String?
    let title: String
    let status: String
}

struct ServiceDownload: Identifiable, Hashable, Sendable {

    let id: String
    let title: String
    let detail: String
}

struct ServiceArrival: Identifiable, Hashable, Sendable {

    let id: String
    let title: String
    let detail: String
    let date: Date?
}

struct RequestShelf: Identifiable, Hashable, Sendable {

    let id: String
    let title: String
    let titles: [RequestTitle]
}

struct MediaRequestFailure: Error {

    let message: String
}

/// Talks to Seerr for the ask, and to Sonarr and Radarr for download and arrival status.
struct MediaRequestClient {

    private let configuration: RequestServicesConfiguration
    private let session: URLSession
    private let decoder = JSONDecoder()

    init(configuration: RequestServicesConfiguration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    func search(_ query: String) async throws -> [RequestTitle] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        var components = URLComponents(url: configuration.seerrURL.appending(path: "api/v1/search"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "query", value: trimmed),
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "language", value: "en"),
        ]
        guard let url = components?.url else { throw MediaRequestFailure(message: L10n.failed) }

        let page: SearchPage = try await get(url, key: configuration.seerrAPIKey)
        return page.results.compactMap(RequestTitle.init)
    }

    /// The same rows Seerr shows on its own Discover page.
    func recommendationShelves() async -> [RequestShelf] {
        let sliders = await (try? discoverSliders()) ?? []
        let day = Self.todayString()
        var shelves: [RequestShelf] = []

        for slider in sliders where slider.enabled {
            guard let row = RecommendationRow(sliderType: slider.type, day: day) else { continue }

            let titles = await (try? discover(path: row.path, query: row.query)) ?? []
            guard !titles.isEmpty else { continue }

            shelves.append(RequestShelf(id: row.id, title: row.title, titles: titles))
        }
        return shelves
    }

    private func discover(path: String, query: [URLQueryItem]) async throws -> [RequestTitle] {
        var components = URLComponents(
            url: configuration.seerrURL.appending(path: path),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = query
        guard let url = components?.url else { throw MediaRequestFailure(message: L10n.failed) }

        do {
            let page: SearchPage = try await get(url, key: configuration.seerrAPIKey)
            let titles = page.results.compactMap(RequestTitle.init)
            if !titles.isEmpty {
                return titles
            }
        } catch {}

        try? await Task.sleep(for: .seconds(1))
        let retry: SearchPage = try await get(url, key: configuration.seerrAPIKey)
        return retry.results.compactMap(RequestTitle.init)
    }

    private func discoverSliders() async throws -> [DiscoverSliderRecord] {
        let url = configuration.seerrURL.appending(path: "api/v1/settings/discover")
        let sliders: [DiscoverSliderRecord] = try await get(url, key: configuration.seerrAPIKey)
        return sliders.sorted { $0.order < $1.order }
    }

    private static func todayString() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    func request(_ title: RequestTitle) async throws {
        let url = configuration.seerrURL.appending(path: "api/v1/request")
        let payload = RequestPayload(
            mediaType: title.mediaType,
            mediaId: title.tmdbID,
            seasons: title.mediaType == "tv" ? "all" : nil,
            is4k: true
        )
        let body = try JSONEncoder().encode(payload)
        try await send(url, key: configuration.seerrAPIKey, method: "POST", body: body)
        TitleMemory.remember(title.title, id: title.id)
    }

    func openRequests() async throws -> [OpenRequest] {
        var components = URLComponents(url: configuration.seerrURL.appending(path: "api/v1/request"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "take", value: "30"),
            URLQueryItem(name: "skip", value: "0"),
        ]
        guard let url = components?.url else { throw MediaRequestFailure(message: L10n.failed) }

        let page: RequestPage = try await get(url, key: configuration.seerrAPIKey)
        var requests: [OpenRequest] = []
        for item in page.results {
            let key = item.memoryKey
            var name = item.media?.title ?? TitleMemory.title(for: key)
            if name == nil {
                name = await lookupTitle(for: item)
                if let name, let key {
                    TitleMemory.remember(name, id: key)
                }
            }
            requests.append(
                OpenRequest(
                    id: item.id,
                    memoryKey: item.memoryKey,
                    title: name ?? item.fallbackTitle,
                    status: item.statusTitle
                )
            )
        }
        return requests
    }

    func downloads() async throws -> [ServiceDownload] {
        async let sonarr = queue(url: configuration.sonarrURL, key: configuration.sonarrAPIKey, service: "Sonarr")
        async let radarr = queue(url: configuration.radarrURL, key: configuration.radarrAPIKey, service: "Radarr")
        return try await sonarr + radarr
    }

    func arrivals() async throws -> [ServiceArrival] {
        async let sonarr = history(url: configuration.sonarrURL, key: configuration.sonarrAPIKey, service: "Sonarr")
        async let radarr = history(url: configuration.radarrURL, key: configuration.radarrAPIKey, service: "Radarr")
        return try await (sonarr + radarr).sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
    }

    private func lookupTitle(for item: RequestRecord) async -> String? {
        guard let tmdbID = item.media?.tmdbId else { return nil }

        if item.type == "tv" {
            var components = URLComponents(
                url: configuration.sonarrURL.appending(path: "api/v3/series/lookup"),
                resolvingAgainstBaseURL: false
            )
            components?.queryItems = [URLQueryItem(name: "term", value: "tmdb:\(tmdbID)")]
            if let url = components?.url,
               let series: [LookupTitle] = try? await get(url, key: configuration.sonarrAPIKey),
               let title = series.first?.title
            {
                return title
            }
        }

        var components = URLComponents(
            url: configuration.radarrURL.appending(path: "api/v3/movie/lookup/tmdb"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [URLQueryItem(name: "tmdbId", value: String(tmdbID))]
        guard let url = components?.url else { return nil }

        let movie: LookupTitle? = try? await get(url, key: configuration.radarrAPIKey)
        return movie?.title
    }

    private func queue(url: URL, key: String, service: String) async throws -> [ServiceDownload] {
        var components = URLComponents(url: url.appending(path: "api/v3/queue"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "pageSize", value: "40")]
        guard let endpoint = components?.url else { return [] }

        let page: QueuePage = try await get(endpoint, key: key)
        return page.records.map { record in
            ServiceDownload(
                id: "\(service)-\(record.id)",
                title: record.displayTitle,
                detail: record.detail(service: service)
            )
        }
    }

    private func history(url: URL, key: String, service: String) async throws -> [ServiceArrival] {
        var components = URLComponents(url: url.appending(path: "api/v3/history"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "pageSize", value: "12"),
            URLQueryItem(name: "eventType", value: "downloadFolderImported"),
        ]
        guard let endpoint = components?.url else { return [] }

        let page: HistoryPage = try await get(endpoint, key: key)
        return page.records.map { record in
            ServiceArrival(
                id: "\(service)-\(record.id)",
                title: record.displayTitle,
                detail: service,
                date: record.parsedDate
            )
        }
    }

    private func get<T: Decodable>(_ url: URL, key: String) async throws -> T {
        let data = try await send(url, key: key, method: "GET", body: nil)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw MediaRequestFailure(message: L10n.failed)
        }
    }

    @discardableResult
    private func send(_ url: URL, key: String, method: String, body: Data?) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(key, forHTTPHeaderField: "X-Api-Key")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw MediaRequestFailure(message: L10n.failed)
        }

        guard let http = response as? HTTPURLResponse else {
            throw MediaRequestFailure(message: L10n.failed)
        }
        guard (200 ..< 300).contains(http.statusCode) else {
            let message = (try? decoder.decode(APIMessage.self, from: data))?.message
            throw MediaRequestFailure(message: message ?? L10n.failed)
        }

        return data
    }
}

private enum TitleMemory {

    private static let key = "velora.requestTitles"

    static func remember(_ title: String, id: String) {
        var stored = UserDefaults.standard.dictionary(forKey: key) as? [String: String] ?? [:]
        stored[id] = title
        UserDefaults.standard.set(stored, forKey: key)
    }

    static func title(for id: String?) -> String? {
        guard let id else { return nil }

        let stored = UserDefaults.standard.dictionary(forKey: key) as? [String: String]
        return stored?[id]
    }
}

private struct DiscoverSliderRecord: Decodable {
    let type: Int
    let enabled: Bool
    let order: Int
}

private struct RecommendationRow {
    let id: String
    let title: String
    let path: String
    let query: [URLQueryItem]

    init?(sliderType: Int, day: String) {
        let page = URLQueryItem(name: "page", value: "1")
        switch sliderType {
        case 4:
            id = "trending"
            title = L10n.trending
            path = "api/v1/discover/trending"
            query = [page]

        case 5:
            id = "popular-movies"
            title = L10n.popularMovies
            path = "api/v1/discover/movies"
            query = [page]

        case 7:
            id = "upcoming-movies"
            title = L10n.upcomingMovies
            path = "api/v1/discover/movies"
            query = [page, URLQueryItem(name: "primaryReleaseDateGte", value: day)]

        case 9:
            id = "popular-series"
            title = L10n.popularSeries
            path = "api/v1/discover/tv"
            query = [page]

        case 11:
            id = "upcoming-series"
            title = L10n.upcomingSeries
            path = "api/v1/discover/tv"
            query = [page, URLQueryItem(name: "firstAirDateGte", value: day)]

        default:
            return nil
        }
    }
}

private struct RequestPayload: Encodable {

    let mediaType: String
    let mediaId: Int
    let seasons: String?
    let is4k: Bool

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(mediaType, forKey: .mediaType)
        try container.encode(mediaId, forKey: .mediaId)
        try container.encodeIfPresent(seasons, forKey: .seasons)
        try container.encode(is4k, forKey: .is4k)
    }

    private enum CodingKeys: String, CodingKey {
        case mediaType
        case mediaId
        case seasons
        case is4k
    }
}

private struct APIMessage: Decodable {

    let message: String?
}

private struct SearchPage: Decodable {

    let results: [SearchItem]
}

private struct SearchItem: Decodable {

    let id: Int
    let mediaType: String
    let title: String?
    let name: String?
    let releaseDate: String?
    let firstAirDate: String?
    let posterPath: String?
}

private struct RequestPage: Decodable {

    let results: [RequestRecord]
}

private struct RequestRecord: Decodable {

    let id: Int
    let status: Int
    let is4k: Bool?
    let type: String?
    let media: RequestMedia?

    struct RequestMedia: Decodable {
        let tmdbId: Int?
        let status: Int?
        let status4k: Int?
        let title: String?
    }

    var memoryKey: String? {
        guard let tmdbId = media?.tmdbId, let type else { return nil }

        return "\(type)-\(tmdbId)"
    }

    var fallbackTitle: String {
        type == "tv" ? L10n.tvShowsCapitalized : L10n.movies
    }

    var statusTitle: String {
        let availability = is4k == true ? (media?.status4k ?? media?.status) : media?.status
        if availability == 5 {
            return L10n.available
        }
        if availability == 3 || availability == 4 {
            return L10n.downloading
        }
        switch status {
        case 1:
            return L10n.pending
        case 2:
            return L10n.approved
        case 3:
            return L10n.declined
        case 4:
            return L10n.failed
        case 5:
            return L10n.available
        default:
            return L10n.pending
        }
    }
}

private struct LookupTitle: Decodable {

    let title: String?
}

private struct QueuePage: Decodable {

    let records: [QueueRecord]
}

private struct QueueRecord: Decodable {

    let id: Int
    let title: String?
    let status: String?
    let size: Double?
    let sizeleft: Double?
    let movie: NamedItem?
    let series: NamedItem?

    struct NamedItem: Decodable {
        let title: String?
    }

    var displayTitle: String {
        movie?.title ?? series?.title ?? title ?? .emptyDash
    }

    func detail(service: String) -> String {
        let state = (status ?? L10n.downloading).localizedCapitalized
        guard let size, let sizeleft, size > 0 else { return "\(service) · \(state)" }

        let percent = Int(((1 - min(sizeleft, size) / size) * 100).rounded())
        return "\(service) · \(state) · \(percent)%"
    }
}

private struct HistoryPage: Decodable {

    let records: [HistoryRecord]
}

private struct HistoryRecord: Decodable {

    let id: Int
    let sourceTitle: String?
    let date: String?
    let movie: NamedItem?
    let series: NamedItem?

    struct NamedItem: Decodable {
        let title: String?
    }

    var displayTitle: String {
        movie?.title ?? series?.title ?? sourceTitle ?? .emptyDash
    }

    var parsedDate: Date? {
        guard let date else { return nil }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        if let parsed = formatter.date(from: date) {
            return parsed
        }
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: date)
    }
}

fileprivate extension RequestTitle {

    init?(_ item: SearchItem) {
        guard item.mediaType == "movie" || item.mediaType == "tv" else { return nil }

        let name = item.title ?? item.name
        guard let name, !name.isEmpty else { return nil }

        let rawDate = item.releaseDate ?? item.firstAirDate
        let year = rawDate.flatMap { String($0.prefix(4)) }
        let posterURL = item.posterPath.flatMap { path -> URL? in
            guard path.hasPrefix("/") else { return nil }

            return URL(string: "https://image.tmdb.org/t/p/w342\(path)")
        }
        self.init(
            tmdbID: item.id,
            mediaType: item.mediaType,
            title: name,
            year: year,
            posterURL: posterURL
        )
    }
}
