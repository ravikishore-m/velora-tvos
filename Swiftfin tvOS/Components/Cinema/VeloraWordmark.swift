//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

/// The Velora mark: a V of two rounded ribbons, violet over mint, meeting in sky blue.
/// Each ribbon can be drawn in part, for the launch ident.
struct VeloraMark: View {

    let size: CGFloat
    var leadingProgress: CGFloat = 1
    var trailingProgress: CGFloat = 1

    private struct Ribbon: Shape {

        let start: UnitPoint
        let end: UnitPoint

        func path(in rect: CGRect) -> Path {
            Path { path in
                path.move(to: CGPoint(x: rect.minX + start.x * rect.width, y: rect.minY + start.y * rect.height))
                path.addLine(to: CGPoint(x: rect.minX + end.x * rect.width, y: rect.minY + end.y * rect.height))
            }
        }
    }

    private var stroke: StrokeStyle {
        StrokeStyle(lineWidth: size * CinemaTheme.Brand.ribbonWidth, lineCap: .round)
    }

    var body: some View {
        ZStack {
            Ribbon(start: UnitPoint(x: 0.84, y: 0.16), end: UnitPoint(x: 0.5, y: 0.84))
                .trim(from: 0, to: trailingProgress)
                .stroke(
                    LinearGradient(
                        colors: [CinemaTheme.Brand.mint, CinemaTheme.Brand.sky],
                        startPoint: .topTrailing,
                        endPoint: .bottom
                    ),
                    style: stroke
                )

            Ribbon(start: UnitPoint(x: 0.16, y: 0.16), end: UnitPoint(x: 0.5, y: 0.84))
                .trim(from: 0, to: leadingProgress)
                .stroke(
                    LinearGradient(
                        colors: [CinemaTheme.Brand.violet, CinemaTheme.Brand.sky],
                        startPoint: .topLeading,
                        endPoint: .bottom
                    ),
                    style: stroke
                )
                .shadow(color: .black.opacity(0.35), radius: size * 0.03, x: size * 0.02)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// The mark beside the lowercase name, set in rounded type
struct VeloraWordmark: View {

    let size: CGFloat
    /// Sweeps a highlight across the name every few seconds
    var isShimmering = false

    private var name: some View {
        Text(L10n.velora.lowercased())
            .font(.system(size: size, weight: .bold, design: .rounded))
            .tracking(size * CinemaTheme.Brand.letterSpacing)
            .fixedSize()
    }

    var body: some View {
        HStack(spacing: size * 0.2) {
            VeloraMark(size: size * 1.1)

            name
                .foregroundStyle(CinemaTheme.Colors.primaryText)
                .overlay {
                    if isShimmering {
                        ShimmerBand()
                            .mask(name)
                    }
                }
        }
        .shadow(color: .black.opacity(0.4), radius: size * 0.08, y: size * 0.03)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.velora)
        .accessibilityAddTraits(.isHeader)
    }
}

extension VeloraWordmark {

    struct ShimmerBand: View {

        @State
        private var progress: CGFloat = 0

        var body: some View {
            GeometryReader { proxy in
                LinearGradient(
                    colors: [.clear, CinemaTheme.Brand.mint.opacity(0.8), .clear],
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

/// Launch ident: an aurora rises in the dark, the V draws itself ribbon by ribbon,
/// the name lifts in letter by letter, and the whole mark drifts forward and fades into the profile picker.
struct VeloraIntro: View {

    private enum Stage: Int, Comparable {
        case hidden
        case aurora
        case mark
        case name
        case exit

        static func < (lhs: Stage, rhs: Stage) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    /// Called as the mark fades, so the screen behind can start revealing
    let onReveal: () -> Void
    let onFinished: () -> Void

    @State
    private var stage: Stage = .hidden
    @State
    private var leadingProgress: CGFloat = 0
    @State
    private var trailingProgress: CGFloat = 0

    private var letters: [String] {
        L10n.velora.lowercased().map(String.init)
    }

    private func play() async {
        withAnimation(.easeOut(duration: 0.9)) {
            stage = .aurora
        }
        try? await Task.sleep(for: .milliseconds(300))

        stage = .mark
        withAnimation(.easeInOut(duration: 0.45)) {
            leadingProgress = 1
        }
        try? await Task.sleep(for: .milliseconds(330))

        withAnimation(.easeInOut(duration: 0.45)) {
            trailingProgress = 1
        }
        try? await Task.sleep(for: .milliseconds(400))

        stage = .name
        try? await Task.sleep(for: .milliseconds(1100))

        withAnimation(.easeIn(duration: 0.6)) {
            stage = .exit
        }
        try? await Task.sleep(for: .milliseconds(250))

        onReveal()
        try? await Task.sleep(for: .milliseconds(450))

        onFinished()
    }

    private var aurora: some View {
        ZStack {
            Ellipse()
                .fill(CinemaTheme.Brand.violet)
                .frame(width: 1100, height: 520)
                .offset(x: stage >= .mark ? -260 : -420, y: -120)

            Ellipse()
                .fill(CinemaTheme.Brand.mint)
                .frame(width: 900, height: 420)
                .offset(x: stage >= .mark ? 300 : 460, y: 160)

            Ellipse()
                .fill(CinemaTheme.Brand.sky)
                .frame(width: 700, height: 360)
                .offset(y: 40)
                .opacity(0.7)
        }
        .blur(radius: 160)
        .opacity(stage == .hidden ? 0 : stage == .exit ? 0.9 : 0.45)
        .animation(.easeInOut(duration: 2.4), value: stage)
    }

    private var name: some View {
        HStack(spacing: CinemaTheme.Brand.introNameSize * CinemaTheme.Brand.letterSpacing) {
            ForEach(Array(letters.enumerated()), id: \.offset) { index, letter in
                let isShown = stage >= .name

                Text(letter)
                    .offset(y: isShown ? 0 : CinemaTheme.Brand.introNameSize * 0.35)
                    .opacity(isShown ? 1 : 0)
                    .blur(radius: isShown ? 0 : 8)
                    .animation(
                        .spring(response: 0.55, dampingFraction: 0.8).delay(Double(index) * 0.07),
                        value: isShown
                    )
            }
        }
        .font(.system(size: CinemaTheme.Brand.introNameSize, weight: .bold, design: .rounded))
        .foregroundStyle(CinemaTheme.Colors.primaryText)
        .fixedSize()
    }

    var body: some View {
        ZStack {
            CinemaTheme.Brand.night
                .opacity(stage >= .exit ? 0 : 1)
                .animation(.easeIn(duration: 0.6).delay(0.2), value: stage)

            aurora

            VStack(spacing: CinemaTheme.Brand.introNameSize * 0.45) {
                VeloraMark(
                    size: CinemaTheme.Brand.introMarkSize,
                    leadingProgress: leadingProgress,
                    trailingProgress: trailingProgress
                )

                name
            }
            .scaleEffect(stage >= .exit ? 1.15 : 1)
            .opacity(stage >= .exit ? 0 : 1)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task {
            await play()
        }
    }
}
