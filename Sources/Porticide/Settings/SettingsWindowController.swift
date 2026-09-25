import AppKit
import SwiftUI

final class SettingsWindowController: NSWindowController {
    init(settings: SettingsStore, notifier: KillNotifier) {
        let hostingController = NSHostingController(rootView: SettingsView(settings: settings, notifier: notifier))
        hostingController.sizingOptions = .preferredContentSize

        let window = NSWindow(contentViewController: hostingController)
        window.title = "Porticide Settings"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.center()

        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
