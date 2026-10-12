//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import AppKit
import Foundation

let brandAssets = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("Swiftfin tvOS/Resources/Assets.xcassets/App Icon & Top Shelf Image.brandassets")

guard FileManager.default.fileExists(atPath: brandAssets.path) else {
    fatalError("Run from the repository root; missing \(brandAssets.path)")
}

let previewDirectory = CommandLine.arguments.dropFirst().first.map(URL.init(fileURLWithPath:))

let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: sRGB, components: [red, green, blue, alpha])!
}

let red = color(0.9, 0.04, 0.08)
let garnet = color(0.5, 0.01, 0.05)
let night = color(0.02, 0.012, 0.014)
let tip = color(1, 0.16, 0.14)

/// A face of the mark: corners in a unit square, y down, and its colour on the left edge;
/// the same as VeloraMark in the app
struct Face {
    let corners: [(CGFloat, CGFloat)]
    let color: CGColor
}

let faces = [
    Face(corners: [(0.06, 0.66), (0.39, 0.5), (0.96, 0.5), (0.06, 0.8)], color: color(0.3, 0, 0.03)),
    Face(corners: [(0.06, 0.8), (0.96, 0.5), (0.06, 0.94)], color: color(0.58, 0.01, 0.05)),
    Face(corners: [(0.06, 0.06), (0.96, 0.5), (0.06, 0.2)], color: color(1, 0.24, 0.22)),
    Face(corners: [(0.06, 0.2), (0.96, 0.5), (0.39, 0.5), (0.06, 0.34)], color: color(0.74, 0.02, 0.07)),
]

func mix(_ from: CGColor, _ to: CGColor, by amount: CGFloat) -> CGColor {
    let a = from.components!, b = to.components!
    return color(
        a[0] + (b[0] - a[0]) * amount,
        a[1] + (b[1] - a[1]) * amount,
        a[2] + (b[2] - a[2]) * amount
    )
}

func makeContext(width: Int, height: Int) -> CGContext {
    let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: sRGB,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    context.setShouldAntialias(true)
    context.interpolationQuality = .high
    return context
}

func save(_ context: CGContext, to url: URL) {
    let data = NSBitmapImageRep(cgImage: context.makeImage()!).representation(using: .png, properties: [:])!
    try! data.write(to: url)
    print("wrote \(url.lastPathComponent) \(context.width)x\(context.height)")
}

func glow(_ context: CGContext, _ glowColor: CGColor, at center: CGPoint, radius: CGFloat, strength: CGFloat) {
    let gradient = CGGradient(
        colorsSpace: sRGB,
        colors: [glowColor.copy(alpha: strength)!, glowColor.copy(alpha: 0)!] as CFArray,
        locations: [0, 1]
    )!
    context.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: [])
}

/// Deep black with a soft red light behind the centre
func drawAurora(_ context: CGContext, size: CGSize, strength: CGFloat = 1) {
    context.setFillColor(night)
    context.fill(CGRect(origin: .zero, size: size))

    let reach = max(size.width, size.height)
    glow(context, garnet, at: CGPoint(x: size.width * 0.5, y: size.height * 0.5), radius: reach * 0.5, strength: 0.4 * strength)
    glow(context, red, at: CGPoint(x: size.width * 0.56, y: size.height * 0.5), radius: reach * 0.22, strength: 0.22 * strength)
}

/// The sideways, bevelled V in a square of `side` with its bottom-left at `origin`
func drawMark(_ context: CGContext, origin: CGPoint, side: CGFloat) {
    func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: origin.x + x * side, y: origin.y + (1 - y) * side)
    }

    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -side * 0.02), blur: side * 0.08, color: color(0, 0, 0, 0.45))
    context.beginTransparencyLayer(auxiliaryInfo: nil)

    for face in faces {
        context.saveGState()
        context.addLines(between: face.corners.map { point($0.0, $0.1) })
        context.closePath()
        context.clip()
        let gradient = CGGradient(colorsSpace: sRGB, colors: [face.color, mix(face.color, tip, by: 0.4)] as CFArray, locations: [0, 1])!
        context.drawLinearGradient(
            gradient,
            start: point(0, 0.5),
            end: point(1, 0.5),
            options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
        )
        context.restoreGState()
    }

    // Light catching the top edge
    context.setStrokeColor(color(1, 1, 1, 0.6))
    context.setLineWidth(max(1, side * 0.008))
    context.move(to: point(0.06, 0.06))
    context.addLine(to: point(0.96, 0.5))
    context.strokePath()

    context.endTransparencyLayer()
    context.restoreGState()
}

/// The mark alone, centred on `center`, `height` tall
func drawCentredMark(_ context: CGContext, center: CGPoint, height: CGFloat) {
    // The faces span 0.88 of the mark's square vertically and sit slightly left of centre
    let side = height / 0.88
    drawMark(context, origin: CGPoint(x: center.x - side * 0.51, y: center.y - side / 2), side: side)
}

enum Layer {
    /// The icon's dimmer glow, so the mark carries the colour
    case iconBackground
    case iconMark
    case shelf
}

func draw(_ layer: Layer, in context: CGContext, size: CGSize) {
    switch layer {
    case .iconBackground:
        drawAurora(context, size: size, strength: 0.6)
    case .iconMark:
        drawCentredMark(context, center: CGPoint(x: size.width / 2, y: size.height / 2), height: size.height * 0.56)
    case .shelf:
        drawAurora(context, size: size)
        drawCentredMark(context, center: CGPoint(x: size.width / 2, y: size.height / 2), height: size.height * 0.5)
    }
}

func render(_ name: String, in imageset: String, width: Int, height: Int, layer: Layer) {
    let context = makeContext(width: width, height: height)
    draw(layer, in: context, size: CGSize(width: width, height: height))
    save(context, to: brandAssets.appendingPathComponent(imageset).appendingPathComponent(name))
}

let iconBack = "App Icon.imagestack/Back.imagestacklayer/Content.imageset"
let iconFront = "App Icon.imagestack/Front.imagestacklayer/Content.imageset"
let storeBack = "App Icon - App Store.imagestack/Back.imagestacklayer/Content.imageset"
let storeFront = "App Icon - App Store.imagestack/Front.imagestacklayer/Content.imageset"
let shelf = "Top Shelf Image.imageset"
let shelfWide = "Top Shelf Image Wide.imageset"

for (scale, suffix) in [(1, ""), (2, "@2x")] {
    render("back\(suffix).png", in: iconBack, width: 400 * scale, height: 240 * scale, layer: .iconBackground)
    render("front\(suffix).png", in: iconFront, width: 400 * scale, height: 240 * scale, layer: .iconMark)
    render("topshelf\(suffix).png", in: shelf, width: 1920 * scale, height: 720 * scale, layer: .shelf)
    render("topshelf-wide\(suffix).png", in: shelfWide, width: 2320 * scale, height: 720 * scale, layer: .shelf)
}

render("back.png", in: storeBack, width: 1280, height: 768, layer: .iconBackground)
render("front.png", in: storeFront, width: 1280, height: 768, layer: .iconMark)

if let previewDirectory {
    try? FileManager.default.createDirectory(at: previewDirectory, withIntermediateDirectories: true)

    let icon = makeContext(width: 800, height: 480)
    draw(.iconBackground, in: icon, size: CGSize(width: 800, height: 480))
    draw(.iconMark, in: icon, size: CGSize(width: 800, height: 480))
    save(icon, to: previewDirectory.appendingPathComponent("icon-preview.png"))

    let shelfPreview = makeContext(width: 1920, height: 720)
    draw(.shelf, in: shelfPreview, size: CGSize(width: 1920, height: 720))
    save(shelfPreview, to: previewDirectory.appendingPathComponent("shelf-preview.png"))
}
