//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import SwiftUI

struct SplitLoginWindowView<Leading: View, Trailing: View>: View {

    // MARK: - Loading State

    private let isLoading: Bool

    // MARK: - Content Variables

    private let leadingContentView: Leading
    private let trailingContentView: Trailing

    // MARK: - Background Variable

    private let backgroundImageSource: ImageSource?

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: 60) {
            VStack(alignment: .leading, spacing: 22) {
                leadingContentView
            }
            .padding(40)
            .frame(maxWidth: .infinity, alignment: .top)
            .glassEffect(.regular, in: .rect(cornerRadius: 36))

            VStack(alignment: .leading, spacing: 22) {
                trailingContentView
            }
            .padding(40)
            .frame(maxWidth: .infinity, alignment: .top)
            .glassEffect(.regular, in: .rect(cornerRadius: 36))
        }
        .edgePadding()
        .environment(\.colorScheme, .dark)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Image(uiImage: .jellyfinBlobBlue)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: UIDevice.isTV ? 100 : 30)
            }
            ToolbarItem(placement: .topBarTrailing) {
                if isLoading {
                    ProgressView()
                }
            }
        }
        .background {
            CinemaLoginBackground {
                if let backgroundImageSource {
                    ImageView(backgroundImageSource)
                        .aspectRatio(contentMode: .fill)
                        .id(backgroundImageSource)
                        .transition(.opacity)
                        .animation(.linear, value: backgroundImageSource)
                }
            }
        }
    }
}

extension SplitLoginWindowView {

    init(
        isLoading: Bool = false,
        backgroundImageSource: ImageSource? = nil,
        @ViewBuilder leadingContentView: @escaping () -> Leading,
        @ViewBuilder trailingContentView: @escaping () -> Trailing
    ) {
        self.backgroundImageSource = backgroundImageSource
        self.isLoading = isLoading
        self.leadingContentView = leadingContentView()
        self.trailingContentView = trailingContentView()
    }
}
