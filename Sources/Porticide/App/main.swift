import AppKit

let app = NSApplication.shared

#if DEBUG
if let flag = CommandLine.arguments.firstIndex(of: "--render-screenshots") {
    let path = CommandLine.arguments.dropFirst(flag + 1).first ?? "docs/assets"
    do {
        try MainActor.assumeIsolated {
            try ScreenshotRenderer.run(outputDirectory: URL(fileURLWithPath: path))
        }
        exit(0)
    } catch {
        FileHandle.standardError.write(Data("Rendering failed: \(error)\n".utf8))
        exit(1)
    }
}
#endif

let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
