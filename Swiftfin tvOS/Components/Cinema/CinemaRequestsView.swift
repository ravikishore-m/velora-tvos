//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

@MainActor
@Observable
final class CinemaRequestsModel {

    var query = ""
    var results: [RequestTitle] = []
    var downloads: [ServiceDownload] = []
    var arrivals: [ServiceArrival] = []
    var requests: [OpenRequest] = []
    var shelves: [RequestShelf] = []
    var notice: String?
    var isSearching = false
    var requestingIDs: Set<String> = []
    var requestedIDs: Set<String> = []
    var hasLoaded = false

    private let client: MediaRequestClient?

    var isConfigured: Bool {
        client != nil
    }

    init() {
        if let configuration = RequestServicesConfiguration.current {
            client = MediaRequestClient(configuration: configuration)
        } else {
            client = nil
        }
    }

    func loadShelves() async {
        guard let client else { return }

        shelves = await client.recommendationShelves()
    }

    func refresh() async {
        guard let client else { return }

        do {
            async let downloads = client.downloads()
            async let arrivals = client.arrivals()
            async let requests = client.openRequests()
            self.downloads = try await downloads
            self.arrivals = try await arrivals
            let openRequests = try await requests
            self.requests = openRequests
            requestedIDs.formUnion(openRequests.compactMap(\.memoryKey))
            notice = nil
            hasLoaded = true
        } catch let failure as MediaRequestFailure {
            notice = failure.message
            hasLoaded = true
        } catch {
            notice = L10n.failed
            hasLoaded = true
        }
    }

    func search() async {
        guard let client else { return }

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            results = []
            return
        }

        isSearching = true
        defer { isSearching = false }

        do {
            results = try await client.search(trimmed)
            notice = results.isEmpty ? L10n.noResults : nil
        } catch let failure as MediaRequestFailure {
            notice = failure.message
        } catch {
            notice = L10n.failed
        }
    }

    func request(_ title: RequestTitle) async {
        guard let client, !requestingIDs.contains(title.id) else { return }

        requestingIDs.insert(title.id)
        defer { requestingIDs.remove(title.id) }

        do {
            try await client.request(title)
            requestedIDs.insert(title.id)
            notice = L10n.requested
            await refresh()
        } catch let failure as MediaRequestFailure {
            if failure.message.localizedCaseInsensitiveContains("already") {
                requestedIDs.insert(title.id)
            }
            notice = failure.message
        } catch {
            notice = L10n.failed
        }
    }
}

struct CinemaRequestsView: View {

    @Environment(\.tabSafeAreaInsets)
    private var tabSafeAreaInsets

    @State
    private var model = CinemaRequestsModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 36) {
                header
                if model.isConfigured {
                    searchField
                } else {
                    Text(L10n.requestsUnavailable)
                        .font(.title3)
                        .foregroundStyle(CinemaTheme.Colors.secondaryText)
                }

                if let notice = model.notice {
                    Text(notice)
                        .font(.title3)
                        .foregroundStyle(CinemaTheme.Colors.secondaryText)
                }

                if model.results.isNotEmpty {
                    resultRow
                }

                if model.shelves.isNotEmpty {
                    VStack(alignment: .leading, spacing: 28) {
                        ForEach(model.shelves) { shelf in
                            shelfRow(shelf)
                        }
                    }
                }

                if model.hasLoaded {
                    statusSection(L10n.onTheWay, rows: model.downloads.map { ($0.id, $0.title, $0.detail) })
                    statusSection(
                        L10n.justArrived,
                        rows: model.arrivals.prefix(8).map { ($0.id, $0.title, arrivalDetail($0)) }
                    )
                    statusSection(L10n.askedFor, rows: model.requests.map { (String($0.id), $0.title, $0.status) })
                }
            }
            .padding(.horizontal, CinemaTheme.Spacing.edge)
            .padding(.top, tabSafeAreaInsets.top + 24)
            .padding(.bottom, 80)
        }
        .task {
            guard model.isConfigured else { return }

            await model.loadShelves()
            await model.refresh()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(20))
                await model.refresh()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.requests)
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(CinemaTheme.Colors.primaryText)
            Text(L10n.requestsSubtitle)
                .font(.title3)
                .foregroundStyle(CinemaTheme.Colors.secondaryText)
                .frame(maxWidth: 980, alignment: .leading)
        }
    }

    private var searchField: some View {
        HStack(spacing: 24) {
            TextField(L10n.search, text: $model.query)
                .textFieldStyle(.plain)
                .font(.title2)
                .padding(.horizontal, 28)
                .padding(.vertical, 18)
                .background(CinemaTheme.Colors.placeholder, in: Capsule())
                .onSubmit {
                    Task { await model.search() }
                }

            Button(L10n.search, systemImage: "magnifyingglass") {
                Task { await model.search() }
            }
            .buttonStyle(.cinemaAction)
            .disabled(model.isSearching)
        }
    }

    private var resultRow: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 28) {
                ForEach(model.results) { title in
                    resultCard(title)
                }
            }
            .padding(.vertical, 8)
        }
    }

    private func shelfRow(_ shelf: RequestShelf) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(shelf.title)
                .font(CinemaTheme.Typography.rowTitle)
                .foregroundStyle(CinemaTheme.Colors.primaryText)
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 28) {
                    ForEach(shelf.titles) { title in
                        resultCard(title)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }

    private func resultCard(_ title: RequestTitle) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            ImageView(title.posterURL)
                .image { image in
                    image
                        .resizable()
                        .scaledToFill()
                }
                .frame(width: 220, height: 330)
                .background(CinemaTheme.Colors.placeholder)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Text(title.title)
                .font(.headline)
                .foregroundStyle(CinemaTheme.Colors.primaryText)
                .lineLimit(2)
                .frame(width: 220, alignment: .leading)

            if let year = title.year {
                Text(year)
                    .font(.callout)
                    .foregroundStyle(CinemaTheme.Colors.secondaryText)
            }

            Button(model.requestedIDs.contains(title.id) ? L10n.requested : L10n.request) {
                Task { await model.request(title) }
            }
            .buttonStyle(.cinemaAction)
            .disabled(model.requestingIDs.contains(title.id) || model.requestedIDs.contains(title.id))
        }
    }

    private func statusSection(_ title: String, rows: [(id: String, title: String, detail: String)]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(CinemaTheme.Typography.rowTitle)
                .foregroundStyle(CinemaTheme.Colors.primaryText)
            if rows.isEmpty {
                Text(L10n.noResults)
                    .font(.title3)
                    .foregroundStyle(CinemaTheme.Colors.tertiaryText)
            } else {
                ForEach(rows, id: \.id) { row in
                    statusRow(title: row.title, detail: row.detail)
                }
            }
        }
    }

    private func statusRow(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(CinemaTheme.Colors.primaryText)
            Text(detail)
                .font(.callout)
                .foregroundStyle(CinemaTheme.Colors.secondaryText)
        }
        .frame(maxWidth: 900, alignment: .leading)
    }

    private func arrivalDetail(_ item: ServiceArrival) -> String {
        guard let date = item.date else { return item.detail }

        let formatted = date.formatted(date: .abbreviated, time: .omitted)
        return "\(item.detail) · \(formatted)"
    }
}
