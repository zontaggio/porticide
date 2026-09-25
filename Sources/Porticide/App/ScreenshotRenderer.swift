#if DEBUG
import AppKit
import ImageIO
import PorticideKit
import SwiftUI
import UniformTypeIdentifiers

/// Renders the popover with demo data for the README: `Porticide --render-screenshots <dir>`.
///
/// Uses an offscreen window, so no screen recording permission is needed. The stop
/// animation is driven by a frozen clock to export it frame by frame as a GIF.
@MainActor
enum ScreenshotRenderer {
    static func run(outputDirectory: URL) throws {
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

        for scheme in [ColorScheme.light, .dark] {
            let name = scheme == .light ? "popover-light" : "popover-dark"
            let (viewModel, settings) = makeDemo()
            try write(render(viewModel: viewModel, settings: settings, scheme: scheme), to: outputDirectory.appendingPathComponent("\(name).png"))
        }

        let (_, settings) = makeDemo()
        let settingsView = SettingsView(settings: settings, notifier: nil)
        try write(render(settingsView, scheme: .dark, background: Color(white: 0.13)), to: outputDirectory.appendingPathComponent("settings-dark.png"))

        try renderStopAnimation(to: outputDirectory.appendingPathComponent("stop-animation.gif"))
        print("Screenshots written to \(outputDirectory.path)")
    }

    // MARK: - Demo data

    static let demoEntries: [PortEntry] = [
        demo(3000, "node", .nextjs, detail: "v14.2.3", project: "~/code/acme/dashboard"),
        demo(5173, "node", .vite, detail: "v5.4.2", project: "~/code/acme/web"),
        demo(6006, "node", .storybook, project: "~/code/acme/design-system"),
        demo(8000, "python3.12", .uvicorn, project: "~/code/acme/api"),
        demo(8501, "python3.12", .streamlit, detail: "v1.38.0", project: "~/code/labs/forecast"),
        demo(5432, "postgres", .postgres, executable: "/opt/homebrew/opt/postgresql@16/bin/postgres"),
        demo(6379, "redis-server", .redis, executable: "/opt/homebrew/opt/redis/bin/redis-server"),
    ]

    private static func demo(
        _ port: Int, _ process: String, _ kind: ServiceKind,
        detail: String? = nil, project: String? = nil, executable: String? = nil
    ) -> PortEntry {
        PortEntry(
            socket: ListeningSocket(port: port, pid: Int32(40_000 + port), processName: process, user: NSUserName(), transport: .tcp),
            executablePath: executable,
            commandLine: nil,
            projectPath: project.map { ($0 as NSString).expandingTildeInPath },
            service: ServiceInfo(kind: kind, detail: detail)
        )
    }

    private static func makeDemo(entries: [PortEntry] = demoEntries) -> (PortListViewModel, SettingsStore) {
        let defaults = UserDefaults(suiteName: "porticide.screenshots")!
        defaults.removePersistentDomain(forName: "porticide.screenshots")
        let settings = SettingsStore(defaults: defaults)
        let viewModel = PortListViewModel(settings: settings, notifier: nil) {}
        viewModel.showDemo(entries)
        return (viewModel, settings)
    }

    // MARK: - Stop animation

    private static func renderStopAnimation(to url: URL) throws {
        let (viewModel, settings) = makeDemo()
        let target = demoEntries[1] // Vite on :5173
        let start = Date(timeIntervalSinceReferenceDate: 0)
        viewModel.previewStop(target.id, startedAt: start)

        let fps = 30.0
        var frames: [(CGImage, Double)] = []
        // Hold on the full list, play the stop, then hold on the result.
        viewModel.clockOverride = start
        frames.append((try render(viewModel: viewModel, settings: settings, scheme: .dark), 1.2))
        for frame in 1...Int(StopEffect.duration * fps) {
            viewModel.clockOverride = start.addingTimeInterval(Double(frame) / fps)
            frames.append((try render(viewModel: viewModel, settings: settings, scheme: .dark), 1 / fps))
        }
        let (after, afterSettings) = makeDemo(entries: demoEntries.filter { $0.id != target.id })
        frames.append((try render(viewModel: after, settings: afterSettings, scheme: .dark), 1.6))

        // Frames must share a size; the list is shorter at the end, so pad to the tallest.
        let width = frames.map(\.0.width).max()!
        let height = frames.map(\.0.height).max()!
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.gif.identifier as CFString, frames.count, nil) else {
            throw RenderError.gif
        }
        CGImageDestinationSetProperties(destination, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]] as CFDictionary)
        for (image, delay) in frames {
            let padded = pad(image, width: width, height: height)
            CGImageDestinationAddImage(destination, padded, [
                kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFUnclampedDelayTime: delay],
            ] as CFDictionary)
        }
        guard CGImageDestinationFinalize(destination) else { throw RenderError.gif }
    }

    // MARK: - Rendering

    enum RenderError: Error { case capture, gif }

    private static func render(viewModel: PortListViewModel, settings: SettingsStore, scheme: ColorScheme) throws -> CGImage {
        try render(
            PopoverView(viewModel: viewModel, settings: settings),
            scheme: scheme,
            background: scheme == .dark ? Color(white: 0.17) : Color(white: 0.965)
        )
    }

    private static func render(_ content: some View, scheme: ColorScheme, background: Color) throws -> CGImage {
        let root = content
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.5))
            .shadow(color: .black.opacity(0.25), radius: 18, y: 8)
            .padding(32)
            .environment(\.colorScheme, scheme)

        let hostingView = NSHostingView(rootView: root)
        hostingView.appearance = NSAppearance(named: scheme == .dark ? .darkAqua : .aqua)
        let size = hostingView.fittingSize
        let window = NSWindow(contentRect: NSRect(origin: CGPoint(x: -10_000, y: -10_000), size: size), styleMask: .borderless, backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.contentView = hostingView
        hostingView.frame = NSRect(origin: .zero, size: size)
        hostingView.layoutSubtreeIfNeeded()
        // Let SwiftUI settle layout and fonts before capturing.
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))

        guard let rep = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else { throw RenderError.capture }
        hostingView.cacheDisplay(in: hostingView.bounds, to: rep)
        guard let image = rep.cgImage else { throw RenderError.capture }
        return image
    }

    private static func pad(_ image: CGImage, width: Int, height: Int) -> CGImage {
        let context = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        // GIFs have no partial transparency, so flatten onto GitHub's dark background.
        context.setFillColor(CGColor(srgbRed: 0x0D / 255, green: 0x11 / 255, blue: 0x17 / 255, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.draw(image, in: CGRect(x: 0, y: height - image.height, width: image.width, height: image.height))
        return context.makeImage()!
    }

    private static func write(_ image: CGImage, to url: URL) throws {
        let rep = NSBitmapImageRep(cgImage: image)
        try rep.representation(using: .png, properties: [:])!.write(to: url)
    }
}
#endif
