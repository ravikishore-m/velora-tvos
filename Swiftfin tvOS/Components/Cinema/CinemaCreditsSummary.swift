//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

/// "Starring … / Director …", shown in the bottom corner of the details page
struct CinemaCreditsSummary: View {

    let item: BaseItemDto

    private func names(of kind: PersonKind, limit: Int) -> String? {
        let names = (item.people ?? [])
            .filter { $0.type == kind }
            .compactMap(\.name)
            .prefix(limit)

        return names.isEmpty ? nil : names.joined(separator: ", ")
    }

    @ViewBuilder
    private func line(_ title: String, _ names: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: CinemaTheme.Credits.titleSpacing) {
            Text(title)
                .foregroundStyle(CinemaTheme.Colors.tertiaryText)

            Text(names)
                .foregroundStyle(CinemaTheme.Colors.primaryText)
                .lineLimit(1)
        }
    }

    var body: some View {
        let cast = names(of: .actor, limit: CinemaTheme.Credits.castLimit)
        let directors = names(of: .director, limit: CinemaTheme.Credits.directorLimit)

        if cast != nil || directors != nil {
            VStack(alignment: .leading, spacing: CinemaTheme.Credits.lineSpacing) {
                if let cast {
                    line(L10n.starring, cast)
                }

                if let directors {
                    line(L10n.director, directors)
                }
            }
            .font(CinemaTheme.Credits.font)
            .accessibilityElement(children: .combine)
        }
    }
}

/// "Recently added" and "New episodes" in a glass pill, led by a mint dot
struct CinemaNewContentPill: View {

    let label: String
    var font: Font = .system(size: CinemaTheme.NewContent.fontSize, weight: .bold, design: .rounded)

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(CinemaTheme.Brand.mint)
                .frame(width: CinemaTheme.NewContent.dotSize, height: CinemaTheme.NewContent.dotSize)
                .shadow(color: CinemaTheme.Brand.mint, radius: 4)

            Text(label)
                .font(font)
                .foregroundStyle(CinemaTheme.Colors.primaryText)
                .lineLimit(1)
        }
        .padding(.horizontal, CinemaTheme.NewContent.horizontalPadding)
        .padding(.vertical, CinemaTheme.NewContent.verticalPadding)
        .glassEffect(.regular, in: Capsule())
    }
}

/// The new content pill above the title
struct CinemaNewContentTag: View {

    let item: BaseItemDto

    var body: some View {
        if let label = item.cinemaNewContentLabel {
            CinemaNewContentPill(label: label, font: CinemaTheme.Credits.font.weight(.semibold))
        }
    }
}

extension BaseItemDto {

    /// The "Recently added" and "New Episodes" labels for content added within the last two weeks
    var cinemaNewContentLabel: String? {
        let cutoff = Date.now.addingTimeInterval(-CinemaTheme.NewContent.window)

        func isRecent(_ date: Date?) -> Bool {
            date.map { $0 > cutoff } ?? false
        }

        switch type {
        case .series:
            if isRecent(dateCreated) {
                return L10n.recentlyAdded
            }
            if isRecent(dateLastMediaAdded) {
                return L10n.newEpisodes
            }

        case .episode:
            if isRecent(dateCreated) {
                return L10n.newEpisode
            }

        default:
            if isRecent(dateCreated) {
                return L10n.recentlyAdded
            }
        }

        return nil
    }
}
