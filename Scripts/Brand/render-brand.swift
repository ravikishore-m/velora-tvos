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
func drawAurora(_ context: CGContext, size: CGSize) {
    context.setFillColor(night)
    context.fill(CGRect(origin: .zero, size: size))

    let reach = max(size.width, size.height)
    glow(context, violet, at: CGPoint(x: size.width * 0.28, y: size.height * 0.7), radius: reach * 0.55, strength: 0.75)
    glow(context, mint, at: CGPoint(x: size.width * 0.78, y: size.height * 0.25), radius: reach * 0.45, strength: 0.45)
    glow(context, sky, at: CGPoint(x: size.width * 0.5, y: size.height * 0.45), radius: reach * 0.35, strength: 0.35)
}

/// The V: two round-capped ribbons, violet over mint, in a square of `side` with its bottom-left at `origin`
func drawMark(_ context: CGContext, origin: CGPoint, side: CGFloat) {
    func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: origin.x + x * side, y: origin.y + (1 - y) * side)
    }

    func ribbon(from start: CGPoint, to end: CGPoint, colors: [CGColor], shadow: Bool) {
        let path = CGMutablePath()
        path.move(to: start)
        path.addLine(to: end)
        let outline = path.copy(strokingWithWidth: side * 0.2, lineCap: .round, lineJoin: .round, miterLimit: 10)

        if shadow {
            context.saveGState()
            context.setShadow(offset: CGSize(width: side * 0.02, height: 0), blur: side * 0.06, color: color(0, 0, 0, 0.35))
            context.addPath(outline)
            context.setFillColor(colors[0])
            context.fillPath()
            context.restoreGState()
        }

        context.saveGState()
        context.addPath(outline)
        context.clip()
        let gradient = CGGradient(colorsSpace: sRGB, colors: colors as CFArray, locations: [0, 1])!
        context.drawLinearGradient(gradient, start: start, end: end, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        context.restoreGState()
    }

    ribbon(from: point(0.84, 0.16), to: point(0.5, 0.84), colors: [mint, sky], shadow: false)
    ribbon(from: point(0.16, 0.16), to: point(0.5, 0.84), colors: [violet, sky], shadow: true)
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

func render(_ name: String, in imageset: String, width: Int, height: Int, background: Bool, lockupWidth: CGFloat?) {
    let context = makeContext(width: width, height: height)
    let size = CGSize(width: width, height: height)

    if background {
        drawAurora(context, size: size)
    }
    if let lockupWidth {
        drawLockup(context, center: CGPoint(x: size.width / 2, y: size.height / 2), width: lockupWidth)
    }

    save(context, to: brandAssets.appendingPathComponent(imageset).appendingPathComponent(name))
}

let iconBack = "App Icon.imagestack/Back.imagestacklayer/Content.imageset"
let iconFront = "App Icon.imagestack/Front.imagestacklayer/Content.imageset"
let storeBack = "App Icon - App Store.imagestack/Back.imagestacklayer/Content.imageset"
let storeFront = "App Icon - App Store.imagestack/Front.imagestacklayer/Content.imageset"
let shelf = "Top Shelf Image.imageset"
let shelfWide = "Top Shelf Image Wide.imageset"

for (scale, suffix) in [(1, ""), (2, "@2x")] {
    render("back\(suffix).png", in: iconBack, width: 400 * scale, height: 240 * scale, background: true, lockupWidth: nil)
    render(
        "front\(suffix).png",
        in: iconFront,
        width: 400 * scale,
        height: 240 * scale,
        background: false,
        lockupWidth: CGFloat(400 * scale) * 0.72
    )
    render(
        "topshelf\(suffix).png",
        in: shelf,
        width: 1920 * scale,
        height: 720 * scale,
        background: true,
        lockupWidth: CGFloat(720 * scale) * 1.3
    )
    render(
        "topshelf-wide\(suffix).png",
        in: shelfWide,
        width: 2320 * scale,
        height: 720 * scale,
        background: true,
        lockupWidth: CGFloat(720 * scale) * 1.3
    )
}

render("back.png", in: storeBack, width: 1280, height: 768, background: true, lockupWidth: nil)
render("front.png", in: storeFront, width: 1280, height: 768, background: false, lockupWidth: 1280 * 0.72)

if let previewDirectory {
    try? FileManager.default.createDirectory(at: previewDirectory, withIntermediateDirectories: true)
    let context = makeContext(width: 800, height: 480)
    drawAurora(context, size: CGSize(width: 800, height: 480))
    drawLockup(context, center: CGPoint(x: 400, y: 240), width: 800 * 0.72)
    save(context, to: previewDirectory.appendingPathComponent("icon-preview.png"))
}
