//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

/// Red condensed RKPLEX wordmark whose outer letters stand taller, after the Netflix logo
struct RKPlexWordmark: View {

    let size: CGFloat
    /// Sweeps a highlight across the letters every few seconds
    var isShimmering = false

    private var letters: [String] {
        L10n.rkPlex.uppercased().map(String.init)
    }

    private func archScale(at index: Int) -> CGFloat {
        let middle = CGFloat(letters.count - 1) / 2
        guard middle > 0 else { return 1 }

        let distance = abs(CGFloat(index) - middle) / middle
        return 1 + CinemaTheme.Brand.archDepth * distance * distance
    }

    private var lettering: some View {
        HStack(spacing: size * CinemaTheme.Brand.letterSpacing) {
            ForEach(Array(letters.enumerated()), id: \.offset) { index, letter in
                Text(letter)
                    .scaleEffect(x: 1, y: archScale(at: index))
            }
        }
        .font(.system(size: size, weight: .black).width(.condensed))
        .fixedSize()
    }

    var body: some View {
        lettering
            .foregroundStyle(CinemaTheme.Brand.fill)
            .overlay {
                if isShimmering {
                    ShimmerBand()
                        .mask(lettering)
                }
            }
            .shadow(color: .black.opacity(0.55), radius: size * 0.06, y: size * 0.03)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(L10n.rkPlex)
            .accessibilityAddTraits(.isHeader)
    }
}

extension RKPlexWordmark {

    private struct ShimmerBand: View {

        @State
        private var progress: CGFloat = 0

        var body: some View {
            GeometryReader { proxy in
                LinearGradient(
                    colors: [.clear, .white.opacity(0.7), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: proxy.size.width * 0.4)
                .rotationEffect(.degrees(16))
                .offset(x: (progress * 1.8 - 0.5) * proxy.size.width)
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .task {
                while !Task.isCancelled {
                    var reset = Transaction()
                    reset.disablesAnimations = true
                    withTransaction(reset) {
                        progress = 0
                    }

                    try? await Task.sleep(for: .milliseconds(60))

                    withAnimation(.easeInOut(duration: CinemaTheme.Brand.shimmerDuration)) {
                        progress = 1
                    }

                    try? await Task.sleep(for: CinemaTheme.Brand.shimmerInterval)
                }
            }
        }
    }
}

/// Launch ident: the wordmark springs in over black, light ribbons burst from behind it,
/// then it rushes towards the viewer to reveal the profile picker.
struct RKPlexIntro: View {

    private enum Stage: Int, Comparable {
        case hidden
        case appear
        case ribbons
        case zoom

        static func < (lhs: Stage, rhs: Stage) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    /// Called as the wordmark rushes forward, so the screen behind can start revealing
    let onReveal: () -> Void
    let onFinished: () -> Void

    @State
    private var stage: Stage = .hidden

    private var wordmarkScale: CGFloat {
        switch stage {
        case .hidden: 0.6
        case .appear: 1
        case .ribbons: 1.08
        case .zoom: 7
        }
    }

    private func play() async {
        withAnimation(.spring(response: 0.7, dampingFraction: 0.72)) {
            stage = .appear
        }
        try? await Task.sleep(for: .milliseconds(850))

        withAnimation(.easeOut(duration: 0.6)) {
            stage = .ribbons
        }
        try? await Task.sleep(for: .milliseconds(600))

        onReveal()
        withAnimation(.easeIn(duration: 0.6)) {
            stage = .zoom
        }
        try? await Task.sleep(for: .milliseconds(650))

        onFinished()
    }

    var body: some View {
        ZStack {
            Color.black
                .opacity(stage == .zoom ? 0 : 1)

            RadialGradient(
                colors: [CinemaTheme.Colors.accent.opacity(0.45), .clear],
                center: .center,
                startRadius: 0,
                endRadius: CinemaTheme.Brand.introSize * 3
            )
            .opacity(stage >= .appear && stage < .zoom ? 1 : 0)

            RibbonBurst(isExpanded: stage >= .ribbons)
                .opacity(stage == .zoom ? 0 : 1)

            RKPlexWordmark(size: CinemaTheme.Brand.introSize, isShimmering: stage >= .appear)
                .scaleEffect(wordmarkScale)
                .opacity(stage == .hidden || stage == .zoom ? 0 : 1)
                .blur(radius: stage == .zoom ? 16 : 0)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task {
            await play()
        }
    }
}

extension RKPlexIntro {

    /// Vertical streaks of colour that stretch out from behind the wordmark
    private struct RibbonBurst: View {

        let isExpanded: Bool

        private static let widths: [CGFloat] = [4, 10, 6, 14, 3, 8, 5]

        private func color(at index: Int) -> Color {
            let palette = CinemaTheme.Brand.ribbonPalette
            return palette[(index * 5) % palette.count]
        }

        var body: some View {
            HStack(spacing: 3) {
                ForEach(0 ..< CinemaTheme.Brand.introRibbonCount, id: \.self) { index in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, color(at: index), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: Self.widths[index % Self.widths.count])
                        .scaleEffect(x: 1, y: isExpanded ? 1 : 0.02)
                        .animation(
                            .easeOut(duration: 0.7).delay(Double(index % 7) * 0.03),
                            value: isExpanded
                        )
                }
            }
            .frame(width: CinemaTheme.Brand.introSize * 3.4)
            .blur(radius: 1.5)
            .blendMode(.screen)
        }
    }
}
