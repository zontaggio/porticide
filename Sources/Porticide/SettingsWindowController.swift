import AppKit
import SwiftUI

final class SettingsWindowController: NSWindowController {
    init(settings: SettingsStore) {
        let view = SettingsView(settings: settings)
        let hosting = NSHostingView(rootView: view)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 240),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.contentView = hosting
        window.title = "Porticide Settings"
        window.isReleasedWhenClosed = false

        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
// Fix: Settings window not closing properly
