//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

/// The Velora mark: a V laid on its side, so it also reads as play. Each arm is cut like a gem
/// into two bevelled faces, lit from above, that meet in a sharp point on the right.
struct VeloraMark: View {

    private struct Face {
        let corners: [CGPoint]
        let color: Color
    }

    /// Faces in a unit square with y pointing down
    private static let upperArm = [
        Face(
            corners: [CGPoint(x: 0.06, y: 0.06), CGPoint(x: 0.96, y: 0.5), CGPoint(x: 0.06, y: 0.2)],
            color: CinemaTheme.Brand.upperLit
        ),
        Face(
            corners: [CGPoint(x: 0.06, y: 0.2), CGPoint(x: 0.96, y: 0.5), CGPoint(x: 0.39, y: 0.5), CGPoint(x: 0.06, y: 0.34)],
            color: CinemaTheme.Brand.upperShade
        ),
    ]

    private static let lowerArm = [
        Face(
            corners: [CGPoint(x: 0.06, y: 0.66), CGPoint(x: 0.39, y: 0.5), CGPoint(x: 0.96, y: 0.5), CGPoint(x: 0.06, y: 0.8)],
            color: CinemaTheme.Brand.lowerShade
        ),
        Face(
            corners: [CGPoint(x: 0.06, y: 0.8), CGPoint(x: 0.96, y: 0.5), CGPoint(x: 0.06, y: 0.94)],
            color: CinemaTheme.Brand.lowerLit
        ),
    ]

    let size: CGFloat
    /// How much of the upper arm is drawn, from the left
    var upperProgress: CGFloat = 1
    /// How much of the lower arm is drawn, from the left
    var lowerProgress: CGFloat = 1

    private func arm(_ faces: [Face], progress: CGFloat) -> some View {
        ZStack {
            ForEach(faces.indices, id: \.self) { index in
                Polygon(corners: faces[index].corners)
                    .fill(
                        LinearGradient(
                            colors: [faces[index].color, faces[index].color.mix(with: CinemaTheme.Brand.tip, by: 0.4)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
        }
        .mask(alignment: .leading) {
            Rectangle()
                .frame(width: size * progress)
        }
    }

    var body: some View {
        ZStack {
            arm(Self.lowerArm, progress: lowerProgress)

            arm(Self.upperArm, progress: upperProgress)
                .overlay {
                    Polygon(corners: [CGPoint(x: 0.06, y: 0.06), CGPoint(x: 0.96, y: 0.5)], isClosed: false)
                        .stroke(.white.opacity(0.6), lineWidth: max(1, size * 0.008))
                        .mask(alignment: .leading) {
                            Rectangle()
                                .frame(width: size * upperProgress)
                        }
                }
        }
        .frame(width: size, height: size)
        .compositingGroup()
        .shadow(color: .black.opacity(0.4), radius: size * 0.04, y: size * 0.02)
        .accessibilityHidden(true)
    }
}

extension VeloraMark {

    /// Straight edges and sharp corners, scaled from a unit square
    struct Polygon: Shape {

        let corners: [CGPoint]
        var isClosed = true

        func path(in rect: CGRect) -> Path {
            Path { path in
                path.addLines(corners.map { CGPoint(x: rect.minX + $0.x * rect.width, y: rect.minY + $0.y * rect.height) })

                if isClosed {
                    path.closeSubpath()
                }
            }
        }
    }
}

/// The Velora logo: the mark on its own, with an occasional glint across its faces
struct VeloraLogo: View {

    let size: CGFloat
    /// Sweeps a highlight across the mark every few seconds
    var isShimmering = false

    var body: some View {
        VeloraMark(size: size)
            .overlay {
                if isShimmering {
                    ShimmerBand()
                        .mask(VeloraMark(size: size))
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(L10n.velora)
            .accessibilityAddTraits(.isHeader)
    }
}

extension VeloraLogo {

    struct ShimmerBand: View {

        @State
        private var progress: CGFloat = 0

        var body: some View {
            GeometryReader { proxy in
                LinearGradient(
                    colors: [.clear, .white.opacity(0.55), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: proxy.size.width * 0.35)
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

/// Launch ident: an aurora rises in the dark, the two arms of the mark cut in from the left and meet
/// at the point, a glint crosses its faces, and the mark drifts forward and fades into the profile picker.
struct VeloraIntro: View {

    private enum Stage: Int, Comparable {
        case hidden
        case aurora
        case mark
        case glint
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
    private var upperProgress: CGFloat = 0
    @State
    private var lowerProgress: CGFloat = 0
    @State
    private var glintProgress: CGFloat = 0

    private var size: CGFloat {
        CinemaTheme.Brand.introSize
    }

    private func play() async {
        withAnimation(.easeOut(duration: 0.9)) {
            stage = .aurora
        }
        try? await Task.sleep(for: .milliseconds(300))

        stage = .mark
        withAnimation(.easeInOut(duration: 0.5)) {
            upperProgress = 1
        }
        try? await Task.sleep(for: .milliseconds(220))

        withAnimation(.easeInOut(duration: 0.5)) {
            lowerProgress = 1
        }
        try? await Task.sleep(for: .milliseconds(500))

        stage = .glint
        withAnimation(.easeInOut(duration: 0.9)) {
            glintProgress = 1
        }
        try? await Task.sleep(for: .milliseconds(1400))

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
                .fill(CinemaTheme.Brand.red)
                .frame(width: 1100, height: 520)
                .offset(x: stage >= .mark ? -260 : -420, y: -120)

            Ellipse()
                .fill(CinemaTheme.Brand.garnet)
                .frame(width: 900, height: 420)
                .offset(x: stage >= .mark ? 300 : 460, y: 160)

            Ellipse()
                .fill(CinemaTheme.Brand.ember)
                .frame(width: 700, height: 360)
                .offset(y: 40)
                .opacity(0.7)
        }
        .blur(radius: 160)
        .opacity(stage == .hidden ? 0 : stage == .exit ? 0.9 : 0.45)
        .animation(.easeInOut(duration: 2.4), value: stage)
    }

    private var glint: some View {
        LinearGradient(
            colors: [.clear, .white.opacity(0.6), .clear],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(width: size * 0.35)
        .rotationEffect(.degrees(16))
        .offset(x: (glintProgress * 1.8 - 0.9) * size)
        .opacity(stage == .glint ? 1 : 0)
        .mask(VeloraMark(size: size))
    }

    var body: some View {
        ZStack {
            CinemaTheme.Brand.night
                .opacity(stage >= .exit ? 0 : 1)
                .animation(.easeIn(duration: 0.6).delay(0.2), value: stage)

            aurora

            VeloraMark(
                size: size,
                upperProgress: upperProgress,
                lowerProgress: lowerProgress
            )
            .overlay {
                glint
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
