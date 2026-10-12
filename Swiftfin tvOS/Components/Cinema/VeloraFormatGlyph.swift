//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

/// Velora's own symbols for picture and sound formats, drawn in the brand gradient beside each format's name
enum VeloraFormatGlyph {

    /// Four tiles: more pixels, for 4K and HD
    case resolution
    /// A lens around an iris, for Dolby Vision
    case vision
    /// A disc lit from one side, for HDR10, HDR10+ and HLG
    case range
    /// Arcs over a listener, for Dolby Atmos and DTS:X
    case spatial
    /// A waveform, for Dolby Digital, DTS and TrueHD
    case sound
    /// Speakers around a listener, for 5.1 and 7.1
    case channels

    struct GlyphShape: Shape {

        let glyph: VeloraFormatGlyph

        func path(in rect: CGRect) -> Path {
            let side = min(rect.width, rect.height)
            let origin = CGPoint(x: rect.midX - side / 2, y: rect.midY - side / 2)
            let line = side * 0.12

            func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: origin.x + x * side, y: origin.y + y * side)
            }

            func circle(_ x: CGFloat, _ y: CGFloat, radius: CGFloat) -> CGRect {
                CGRect(
                    x: origin.x + (x - radius) * side,
                    y: origin.y + (y - radius) * side,
                    width: radius * 2 * side,
                    height: radius * 2 * side
                )
            }

            func stroked(_ path: Path) -> Path {
                path.strokedPath(StrokeStyle(lineWidth: line, lineCap: .round, lineJoin: .round))
            }

            /// An arc from `start` to `end` degrees, measured clockwise on screen from the right
            func arc(_ x: CGFloat, _ y: CGFloat, radius: CGFloat, from start: Double, to end: Double) -> Path {
                var path = Path()
                let steps = 24
                for step in 0 ... steps {
                    let angle = (start + (end - start) * Double(step) / Double(steps)) * .pi / 180
                    let location = point(x + radius * cos(angle), y + radius * sin(angle))
                    if step == 0 {
                        path.move(to: location)
                    } else {
                        path.addLine(to: location)
                    }
                }
                return path
            }

            var path = Path()

            switch glyph {
            case .resolution:
                let tile = side * 0.38
                let gap = side * 0.12
                let start = (side - tile * 2 - gap) / 2
                for row in 0 ..< 2 {
                    for column in 0 ..< 2 {
                        let frame = CGRect(
                            x: origin.x + start + CGFloat(column) * (tile + gap),
                            y: origin.y + start + CGFloat(row) * (tile + gap),
                            width: tile,
                            height: tile
                        )
                        path.addRoundedRect(in: frame, cornerSize: CGSize(width: tile * 0.3, height: tile * 0.3))
                    }
                }

            case .vision:
                path.addPath(stroked(Path(ellipseIn: circle(0.5, 0.5, radius: 0.42))))
                path.addEllipse(in: circle(0.5, 0.5, radius: 0.17))

            case .range:
                path.addPath(stroked(Path(ellipseIn: circle(0.5, 0.5, radius: 0.42))))
                var half = arc(0.5, 0.5, radius: 0.26, from: -90, to: 90)
                half.closeSubpath()
                path.addPath(half)

            case .spatial:
                path.addEllipse(in: circle(0.5, 0.78, radius: 0.1))
                path.addPath(stroked(arc(0.5, 0.78, radius: 0.32, from: 205, to: 335)))
                path.addPath(stroked(arc(0.5, 0.78, radius: 0.6, from: 215, to: 325)))

            case .sound:
                let heights: [CGFloat] = [0.34, 0.66, 0.9, 0.56, 0.3]
                let width = side * 0.11
                let gap = (side - width * CGFloat(heights.count)) / CGFloat(heights.count + 1)
                for (index, height) in heights.enumerated() {
                    let frame = CGRect(
                        x: origin.x + gap + CGFloat(index) * (width + gap),
                        y: origin.y + (1 - height) / 2 * side,
                        width: width,
                        height: height * side
                    )
                    path.addRoundedRect(in: frame, cornerSize: CGSize(width: width / 2, height: width / 2))
                }

            case .channels:
                path.addEllipse(in: circle(0.5, 0.5, radius: 0.12))
                for index in 0 ..< 6 {
                    let angle = (Double(index) * 60 - 90) * .pi / 180
                    path.addEllipse(in: circle(0.5 + 0.38 * cos(angle), 0.5 + 0.38 * sin(angle), radius: 0.075))
                }
            }

            return path
        }
    }
}

struct VeloraFormatGlyphView: View {

    let glyph: VeloraFormatGlyph
    var size: CGFloat = CinemaTheme.Badge.glyphSize

    var body: some View {
        VeloraFormatGlyph.GlyphShape(glyph: glyph)
            .fill(CinemaTheme.Brand.diagonalGradient)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}
