#!/usr/bin/env swift
// Renders Support/AppIcon.icns: the Porticide mark on a dark macOS-style squircle.
//
// Usage: swift scripts/generate-app-icon.swift
// The socket and slash geometry mirrors Sources/Porticide/Design/PorticideMark.swift.

import AppKit

let teal = NSColor(srgbRed: 0x00 / 255, green: 0xBB / 255, blue: 0xA9 / 255, alpha: 1)
let inkTop = NSColor(srgbRed: 0x22 / 255, green: 0x29 / 255, blue: 0x32 / 255, alpha: 1)
let inkBottom = NSColor(srgbRed: 0x0C / 255, green: 0x0F / 255, blue: 0x13 / 255, alpha: 1)
let socketColor = NSColor(srgbRed: 0xF4 / 255, green: 0xF6 / 255, blue: 0xF7 / 255, alpha: 1)

func drawIcon(in context: CGContext, size: CGFloat) {
    // Apple's macOS icon grid: an 824 pt squircle inside a 1024 pt canvas.
    let scale = size / 1024
    let tile = CGRect(x: 100, y: 100, width: 824, height: 824).applying(CGAffineTransform(scaleX: scale, y: scale))
    let tilePath = CGPath(roundedRect: tile, cornerWidth: tile.width * 0.225, cornerHeight: tile.width * 0.225, transform: nil)

    // Drop shadow and background gradient.
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -10 * scale), blur: 28 * scale, color: NSColor.black.withAlphaComponent(0.35).cgColor)
    context.addPath(tilePath)
    context.setFillColor(inkBottom.cgColor)
    context.fillPath()
    context.restoreGState()

    context.saveGState()
    context.addPath(tilePath)
    context.clip()
    let gradient = CGGradient(colorsSpace: nil, colors: [inkTop.cgColor, inkBottom.cgColor] as CFArray, locations: [0, 1])!
    context.drawLinearGradient(gradient, start: CGPoint(x: tile.midX, y: tile.maxY), end: CGPoint(x: tile.midX, y: tile.minY), options: [])
    // Soft teal glow behind the mark.
    let glow = CGGradient(colorsSpace: nil, colors: [teal.withAlphaComponent(0.28).cgColor, teal.withAlphaComponent(0).cgColor] as CFArray, locations: [0, 1])!
    context.drawRadialGradient(glow, startCenter: CGPoint(x: tile.midX, y: tile.midY), startRadius: 0, endCenter: CGPoint(x: tile.midX, y: tile.midY), endRadius: tile.width * 0.55, options: [])
    context.restoreGState()

    // The mark, in a unit square with y pointing down like the SwiftUI shapes.
    let mark = tile.insetBy(dx: tile.width * 0.16, dy: tile.width * 0.16)
    func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: mark.minX + x * mark.width, y: mark.maxY - y * mark.height)
    }

    context.beginTransparencyLayer(auxiliaryInfo: nil)
    let corners = [
        point(0.14, 0.20), point(0.86, 0.20), point(0.86, 0.68), point(0.66, 0.68),
        point(0.66, 0.84), point(0.34, 0.84), point(0.34, 0.68), point(0.14, 0.68),
    ]
    let socket = CGMutablePath()
    let last = corners[corners.count - 1]
    socket.move(to: CGPoint(x: (last.x + corners[0].x) / 2, y: (last.y + corners[0].y) / 2))
    for index in corners.indices {
        socket.addArc(tangent1End: corners[index], tangent2End: corners[(index + 1) % corners.count], radius: 0.06 * mark.width)
    }
    socket.closeSubpath()
    for x in [0.29, 0.43, 0.57, 0.71] as [CGFloat] {
        let slot = CGRect(x: point(x - 0.03, 0).x, y: point(0, 0.40).y, width: 0.06 * mark.width, height: 0.13 * mark.height)
        socket.addRoundedRect(in: slot, cornerWidth: slot.width / 2, cornerHeight: slot.width / 2)
    }
    context.addPath(socket)
    context.setFillColor(socketColor.cgColor)
    context.fillPath(using: .evenOdd)

    let slash = CGMutablePath()
    slash.move(to: point(0.06, 0.72))
    slash.addLine(to: point(0.94, 0.46))
    context.setLineCap(.round)
    context.setBlendMode(.clear)
    context.setLineWidth(mark.width * 0.2)
    context.addPath(slash)
    context.strokePath()
    context.setBlendMode(.normal)
    context.setShadow(offset: .zero, blur: 24 * scale, color: teal.withAlphaComponent(0.6).cgColor)
    context.setStrokeColor(teal.cgColor)
    context.setLineWidth(mark.width * 0.1)
    context.addPath(slash)
    context.strokePath()
    context.endTransparencyLayer()
}

func png(size: Int) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    let context = NSGraphicsContext(bitmapImageRep: rep)!
    drawIcon(in: context.cgContext, size: CGFloat(size))
    context.flushGraphics()
    return rep.representation(using: .png, properties: [:])!
}

let root = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent().deletingLastPathComponent()
let iconset = FileManager.default.temporaryDirectory.appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

for points in [16, 32, 128, 256, 512] {
    try png(size: points).write(to: iconset.appendingPathComponent("icon_\(points)x\(points).png"))
    try png(size: points * 2).write(to: iconset.appendingPathComponent("icon_\(points)x\(points)@2x.png"))
}
try png(size: 1024).write(to: root.appendingPathComponent("docs/assets/app-icon.png"))

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconset.path, "-o", root.appendingPathComponent("Support/AppIcon.icns").path]
try iconutil.run()
iconutil.waitUntilExit()
print("Wrote Support/AppIcon.icns and docs/assets/app-icon.png")
