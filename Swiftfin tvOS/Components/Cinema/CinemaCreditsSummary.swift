//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

/// "Starring … / Director …", shown in the bottom corner of the Apple TV app's details page
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

/// An outlined tag above the title, like the Apple TV app's "New"
struct CinemaNewContentTag: View {

    let item: BaseItemDto

    var body: some View {
        if let label = item.cinemaNewContentLabel {
            Text(label)
                .font(CinemaTheme.Credits.font.weight(.semibold))
                .foregroundStyle(CinemaTheme.Colors.primaryText)
                .padding(.horizontal, CinemaTheme.NewContent.horizontalPadding)
                .padding(.vertical, CinemaTheme.NewContent.verticalPadding)
                .overlay {
                    Capsule()
                        .strokeBorder(CinemaTheme.Colors.secondaryText, lineWidth: CinemaTheme.Badge.outlineWidth)
                }
        }
    }
}

extension BaseItemDto {

    /// Netflix's "Recently added" and "New Episodes" labels for content added within the last two weeks
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
