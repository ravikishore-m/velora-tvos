//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

/// Information, Languages and Accessibility columns on a glass panel at the bottom of a details page
struct CinemaItemInfoGroup: ContentGroup {

    let id: String
    @SharedBaseItem
    var item: BaseItemDto

    func body(with viewModel: Empty) -> Body {
        Body(item: item)
    }

    struct Body: View {

        @SharedBaseItem
        var item: BaseItemDto

        @FocusState
        private var isFocused: Bool

        private var mediaStreams: [MediaStream] {
            item.mediaSources?.first?.mediaStreams ?? item.mediaStreams ?? []
        }

        private static func languageName(_ code: String?) -> String? {
            guard let code, code.isNotEmpty, code.lowercased() != "und" else { return nil }

            return Locale.current.localizedString(forLanguageCode: code) ?? code.uppercased()
        }

        private func languages(of type: MediaStreamType) -> String? {
            var seen: Set<String> = []
            let names = mediaStreams
                .filter { $0.type == type }
                .compactMap { Self.languageName($0.language) }
                .filter { seen.insert($0).inserted }

            return names.isEmpty ? nil : names.joined(separator: ", ")
        }

        private var originalAudio: String? {
            let audioStreams = mediaStreams.filter { $0.type == .audio }
            let stream = audioStreams.first { $0.isDefault == true } ?? audioStreams.first
            return Self.languageName(stream?.language)
        }

        private var directors: String? {
            let names = item.people?
                .filter { $0.type == .director }
                .compactMap(\.name) ?? []

            return names.isEmpty ? nil : names.joined(separator: ", ")
        }

        private var information: [(String, String)] {
            [
                (L10n.studios, item.studios?.compactMap(\.name).joined(separator: ", ")),
                (L10n.genres, item.genres?.joined(separator: ", ")),
                (L10n.released, item.premiereDate?.formatted(date: .long, time: .omitted)),
                (L10n.runtime, item.runTimeLabel),
                (L10n.parentalRating, item.officialRating),
                (L10n.director, directors),
            ]
                .compactMap { title, value in
                    guard let value, value.isNotEmpty else { return nil }

                    return (title, value)
                }
        }

        private var languageRows: [(String, String)] {
            [
                (L10n.originalAudio, originalAudio),
                (L10n.audio, languages(of: .audio)),
                (L10n.subtitles, languages(of: .subtitle)),
            ]
                .compactMap { title, value in
                    guard let value else { return nil }

                    return (title, value)
                }
        }

        private var accessibilityRows: [(CinemaFormatBadges.Badge, String)] {
            var rows: [(CinemaFormatBadges.Badge, String)] = []

            if mediaStreams.hasClosedCaptions {
                rows.append((.closedCaptions, L10n.closedCaptionsDescription))
            }
            if mediaStreams.hasSDHSubtitles {
                rows.append((.sdh, L10n.sdhDescription))
            }
            if mediaStreams.hasAudioDescription {
                rows.append((.audioDescription, L10n.audioDescriptionDescription))
            }

            return rows
        }

        private func column(_ title: String, @ViewBuilder content: () -> some View) -> some View {
            VStack(alignment: .leading, spacing: 18) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(CinemaTheme.Colors.primaryText)

                content()
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }

        private func rows(_ rows: [(String, String)]) -> some View {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(rows, id: \.0) { title, value in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CinemaTheme.Colors.tertiaryText)

                        Text(value)
                            .font(.callout)
                            .foregroundStyle(CinemaTheme.Colors.secondaryText)
                            .lineLimit(3)
                    }
                }
            }
        }

        var body: some View {
            if information.isNotEmpty || languageRows.isNotEmpty || accessibilityRows.isNotEmpty {
                HStack(alignment: .top, spacing: 60) {
                    if information.isNotEmpty {
                        column(L10n.information) {
                            rows(information)
                        }
                    }

                    if languageRows.isNotEmpty {
                        column(L10n.languages) {
                            rows(languageRows)
                        }
                    }

                    if accessibilityRows.isNotEmpty {
                        column(L10n.accessibility) {
                            VStack(alignment: .leading, spacing: 18) {
                                ForEach(accessibilityRows, id: \.0) { badge, description in
                                    HStack(alignment: .top, spacing: 16) {
                                        CinemaFormatBadges.BadgeView(badge: badge)

                                        Text(description)
                                            .font(.caption)
                                            .foregroundStyle(CinemaTheme.Colors.secondaryText)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 40)
                .padding(.horizontal, 40)
                .glassEffect(
                    .regular.tint(isFocused ? CinemaTheme.Colors.accent.opacity(0.2) : nil),
                    in: RoundedRectangle(cornerRadius: 28, style: .continuous)
                )
                .edgePadding(.horizontal)
                .padding(.vertical, 30)
                .focusable()
                .focused($isFocused)
                .animation(CinemaTheme.Focus.animation, value: isFocused)
            }
        }
    }
}
