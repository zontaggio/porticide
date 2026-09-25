#!/usr/bin/env swift
// Downloads service logos from Simple Icons and stores them as vector PDFs in
// Sources/Porticide/Resources/Logos. PDFs load on every macOS version, while
// NSImage only reads loose SVG files from macOS 14.
//
// Usage: swift scripts/update-logos.swift
// The list of logos is read from `logoName` in ServiceKind+Branding.swift.

import AppKit

let simpleIconsVersion = "16.32.0"

let root = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent().deletingLastPathComponent()
let branding = try String(contentsOf: root.appendingPathComponent("Sources/Porticide/Design/ServiceKind+Branding.swift"), encoding: .utf8)
let logoSection = branding.components(separatedBy: "var logoName: String?")[1].components(separatedBy: "var brandColor")[0]
let quoted = try NSRegularExpression(pattern: "\"([a-z0-9]+)\"")
let names = Set(quoted.matches(in: logoSection, range: NSRange(logoSection.startIndex..., in: logoSection)).map {
    String(logoSection[Range($0.range(at: 1), in: logoSection)!])
}).sorted()

let output = root.appendingPathComponent("Sources/Porticide/Resources/Logos")
try? FileManager.default.removeItem(at: output)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

for name in names {
    let url = URL(string: "https://cdn.jsdelivr.net/npm/simple-icons@\(simpleIconsVersion)/icons/\(name).svg")!
    let svg = try Data(contentsOf: url)
    guard let image = NSImage(data: svg) else {
        fatalError("Could not read \(name).svg")
    }

    var mediaBox = CGRect(x: 0, y: 0, width: 24, height: 24)
    let pdfURL = output.appendingPathComponent("\(name).pdf")
    guard let context = CGContext(pdfURL as CFURL, mediaBox: &mediaBox, nil) else {
        fatalError("Could not create \(name).pdf")
    }
    context.beginPDFPage(nil as CFDictionary?)
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
    image.draw(in: mediaBox)
    NSGraphicsContext.current = nil
    context.endPDFPage()
    context.closePDF()
    print("✓ \(name)")
}
print("Wrote \(names.count) logos to \(output.path)")
