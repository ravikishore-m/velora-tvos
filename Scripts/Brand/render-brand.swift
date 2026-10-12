//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import AppKit
import CoreText
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

let violet = color(0.43, 0.33, 1)
let sky = color(0.25, 0.66, 0.98)
let mint = color(0.2, 0.88, 0.72)
let night = color(0.02, 0.024, 0.06)
let fold = color(0.12, 0.16, 0.48)
let foldLight = color(0.19, 0.44, 0.76)

/// Facet corners in a unit square, y down; the same as VeloraMark in the app
let leadingArm: [(CGFloat, CGFloat)] = [(0.05, 0.1), (0.32, 0.1), (0.635, 0.9), (0.365, 0.9)]
let trailingArm: [(CGFloat, CGFloat)] = [(0.68, 0.1), (0.95, 0.1), (0.635, 0.9), (0.365, 0.9)]
let facetRadius: CGFloat = 0.035

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

/// Night sky with violet, sky and mint light pooling behind the centre
func drawAurora(_ context: CGContext, size: CGSize, strength: CGFloat = 1) {
    context.setFillColor(night)
    context.fill(CGRect(origin: .zero, size: size))

    let reach = max(size.width, size.height)
    glow(context, violet, at: CGPoint(x: size.width * 0.28, y: size.height * 0.7), radius: reach * 0.55, strength: 0.75 * strength)
    glow(context, mint, at: CGPoint(x: size.width * 0.78, y: size.height * 0.25), radius: reach * 0.45, strength: 0.45 * strength)
    glow(context, sky, at: CGPoint(x: size.width * 0.5, y: size.height * 0.45), radius: reach * 0.35, strength: 0.35 * strength)
}

/// The folded-ribbon V in a square of `side` with its bottom-left at `origin`
func drawMark(_ context: CGContext, origin: CGPoint, side: CGFloat) {
    func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: origin.x + x * side, y: origin.y + (1 - y) * side)
    }

    func facet(_ corners: [(CGFloat, CGFloat)]) -> CGPath {
        let points = corners.map { point($0.0, $0.1) }
        let path = CGMutablePath()
        path.move(to: CGPoint(x: (points[0].x + points[3].x) / 2, y: (points[0].y + points[3].y) / 2))
        for index in points.indices {
            path.addArc(tangent1End: points[index], tangent2End: points[(index + 1) % points.count], radius: facetRadius * side)
        }
        path.closeSubpath()
        return path
    }

    func fill(_ clips: [CGPath], _ colors: [CGColor], from start: CGPoint, to end: CGPoint) {
        context.saveGState()
        for clip in clips {
            context.addPath(clip)
            context.clip()
        }
        let gradient = CGGradient(colorsSpace: sRGB, colors: colors as CFArray, locations: [0, 1])!
        context.drawLinearGradient(gradient, start: start, end: end, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        context.restoreGState()
    }

    let leading = facet(leadingArm)
    let trailing = facet(trailingArm)
    let sheen = [color(1, 1, 1, 0.32), color(1, 1, 1, 0)]

    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -side * 0.02), blur: side * 0.08, color: color(0, 0, 0, 0.45))
    context.beginTransparencyLayer(auxiliaryInfo: nil)

    fill([leading], [violet, sky], from: point(0.5, 0), to: point(0.5, 1))
    fill([leading], sheen, from: point(0.5, 0), to: point(0.5, 0.5))
    fill([trailing], [mint, sky], from: point(0.5, 0), to: point(0.5, 1))
    fill([trailing], sheen, from: point(0.5, 0), to: point(0.5, 0.5))
    // The ribbon's underside, where the arms overlap at the fold
    fill([leading, trailing], [fold, foldLight], from: point(0.5, 1), to: point(0.5, 0.5))

    context.endTransparencyLayer()
    context.restoreGState()
}

/// The app icon: the mark alone, centred, `fraction` of the canvas height
func drawIconMark(_ context: CGContext, size: CGSize, fraction: CGFloat) {
    let side = size.height * fraction
    drawMark(context, origin: CGPoint(x: (size.width - side) / 2, y: (size.height - side) / 2), side: side)
}

/// Lowercase "velora" in rounded bold, as glyph outlines `height` tall from x-height to baseline
func namePath(height: CGFloat) -> CGPath {
    let base: CGFloat = 1000
    let descriptor = NSFont.systemFont(ofSize: base, weight: .bold).fontDescriptor.withDesign(.rounded)!
    let font = NSFont(descriptor: descriptor, size: base)! as CTFont
    let tracking = base * 0.02
    let scale = height / CTFontGetXHeight(font)

    let combined = CGMutablePath()
    var x: CGFloat = 0
    for character in "velora".utf16 {
        var unichar = character
        var glyph = CGGlyph()
        CTFontGetGlyphsForCharacters(font, &unichar, &glyph, 1)
        var advance = CGSize.zero
        CTFontGetAdvancesForGlyphs(font, .horizontal, &glyph, &advance, 1)

        var transform = CGAffineTransform(scaleX: scale, y: scale).translatedBy(x: x, y: 0)
        if let glyphPath = CTFontCreatePathForGlyph(font, glyph, &transform) {
            combined.addPath(glyphPath)
        }
        x += advance.width + tracking
    }
    return combined
}

/// The mark beside the name, centred in `rect`, fitted to `width`
func drawLockup(_ context: CGContext, center: CGPoint, width: CGFloat) {
    let probeName = namePath(height: 100)
    let probeMark: CGFloat = 100 * 1.9
    let probeGap: CGFloat = 100 * 0.45
    let probeWidth = probeMark + probeGap + probeName.boundingBox.maxX
    let unit = width / probeWidth * 100

    let markSide = unit * 1.9
    let gap = unit * 0.45
    let name = namePath(height: unit)
    let total = markSide + gap + name.boundingBox.maxX
    let left = center.x - total / 2

    drawMark(context, origin: CGPoint(x: left, y: center.y - markSide / 2), side: markSide)

    var place = CGAffineTransform(translationX: left + markSide + gap, y: center.y - name.boundingBox.midY)
    let placed = name.copy(using: &place)!

    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -unit * 0.04), blur: unit * 0.15, color: color(0, 0, 0, 0.5))
    context.addPath(placed)
    context.setFillColor(color(1, 1, 1))
    context.fillPath()
    context.restoreGState()
}

enum Layer {
    /// The icon's dimmer aurora, so the mark carries the colour
    case iconBackground
    case iconMark
    case shelf
}

let iconMarkFraction: CGFloat = 0.68

func draw(_ layer: Layer, in context: CGContext, size: CGSize) {
    switch layer {
    case .iconBackground:
        drawAurora(context, size: size, strength: 0.6)
    case .iconMark:
        drawIconMark(context, size: size, fraction: iconMarkFraction)
    case .shelf:
        drawAurora(context, size: size)
        drawLockup(context, center: CGPoint(x: size.width / 2, y: size.height / 2), width: size.height * 1.3)
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
