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

fileprivate extension RKPlexWordmark {

    struct ShimmerBand: View {

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

/// The R on its own, the app's mark, shaded across the middle like a folded ribbon
struct RKPlexMonogram: View {

    let size: CGFloat
    var isShimmering = false

    private var letter: some View {
        Text(L10n.rkPlex.prefix(1).uppercased())
            .font(.system(size: size, weight: .black).width(.condensed))
            .fixedSize()
    }

    var body: some View {
        letter
            .foregroundStyle(CinemaTheme.Brand.fill)
            .overlay {
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.35),
                        .init(color: .black.opacity(0.4), location: 0.5),
                        .init(color: .clear, location: 0.65),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .mask(letter)
            }
            .overlay {
                if isShimmering {
                    RKPlexWordmark.ShimmerBand()
                        .mask(letter)
                }
            }
            .shadow(color: .black.opacity(0.6), radius: size * 0.05, y: size * 0.03)
            .accessibilityHidden(true)
    }
}

/// Launch ident, after Netflix's: the R springs out of the dark, holds with a glow,
/// then the camera dives into it as it breaks into streaks of light that reveal the profile picker.
struct RKPlexIntro: View {

    private enum Stage: Int, Comparable {
        case hidden
        case appear
        case hold
        case dive
        case reveal

        static func < (lhs: Stage, rhs: Stage) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    /// Called during the dive, so the screen behind can start revealing
    let onReveal: () -> Void
    let onFinished: () -> Void

    @State
    private var stage: Stage = .hidden

    private var monogramScale: CGFloat {
        switch stage {
        case .hidden: 0.6
        case .appear: 1
        case .hold: 1.06
        case .dive, .reveal: CinemaTheme.Brand.diveScale
        }
    }

    private func play() async {
        try? await Task.sleep(for: .milliseconds(150))

        withAnimation(.spring(response: 0.7, dampingFraction: 0.72)) {
            stage = .appear
        }
        try? await Task.sleep(for: .milliseconds(800))

        withAnimation(.easeInOut(duration: 0.7)) {
            stage = .hold
        }
        try? await Task.sleep(for: .milliseconds(750))

        withAnimation(.easeIn(duration: 0.9)) {
            stage = .dive
        }
        try? await Task.sleep(for: .milliseconds(550))

        onReveal()
        try? await Task.sleep(for: .milliseconds(350))

        withAnimation(.easeOut(duration: 0.4)) {
            stage = .reveal
        }
        try? await Task.sleep(for: .milliseconds(420))

        onFinished()
    }

    var body: some View {
        ZStack {
            Color.black
                .opacity(stage >= .reveal ? 0 : 1)

            RadialGradient(
                colors: [CinemaTheme.Colors.accent.opacity(0.45), .clear],
                center: .center,
                startRadius: 0,
                endRadius: CinemaTheme.Brand.monogramSize
            )
            .opacity(stage == .hold ? 1 : stage == .appear ? 0.5 : 0)

            RKPlexMonogram(
                size: CinemaTheme.Brand.monogramSize,
                isShimmering: stage == .hold
            )
            .overlay {
                RibbonBurst()
                    .frame(width: CinemaTheme.Brand.monogramSize * 0.55, height: CinemaTheme.Brand.monogramSize * 0.8)
                    .opacity(stage >= .dive ? 1 : 0)
                    .animation(.easeIn(duration: 0.3), value: stage)
            }
            .scaleEffect(monogramScale)
            .blur(radius: stage == .hidden ? 30 : 0)
            .opacity(stage == .hidden || stage >= .reveal ? 0 : 1)
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

    /// Vertical streaks of colour, the inside of the R once the camera is close enough
    private struct RibbonBurst: View {

        private func color(at index: Int) -> Color {
            let palette = CinemaTheme.Brand.ribbonPalette
            return palette[(index * 5) % palette.count]
        }

        var body: some View {
            HStack(spacing: 1) {
                ForEach(0 ..< CinemaTheme.Brand.introRibbonCount, id: \.self) { index in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, color(at: index), color(at: index).opacity(0.6), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .opacity(index.isMultiple(of: 3) ? 0.55 : 1)
                }
            }
            .blendMode(.screen)
        }
    }
}
