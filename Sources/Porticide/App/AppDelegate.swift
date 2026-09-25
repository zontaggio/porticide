import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settings = SettingsStore()
    private let notifier = KillNotifier()
    private lazy var viewModel = PortListViewModel(settings: settings, notifier: notifier) { [weak self] in
        self?.openSettings()
    }
    private var statusItem: NSStatusItem?
    private let popover = NSPopover()
    private var settingsWindow: SettingsWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setUpStatusItem()

        popover.contentViewController = NSHostingController(rootView: PopoverView(viewModel: viewModel, settings: settings))
        popover.behavior = .transient

        viewModel.start()
    }

    private func setUpStatusItem() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            if let logo = AppAssets.logo?.copy() as? NSImage {
                logo.size = NSSize(width: 18, height: 18)
                button.image = logo
            } else {
                button.title = "🔪"
            }
            button.action = #selector(togglePopover)
            button.target = self
        }
        self.statusItem = statusItem
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private func openSettings() {
        popover.performClose(nil)
        if settingsWindow == nil {
            settingsWindow = SettingsWindowController(settings: settings, notifier: notifier)
        }
        settingsWindow?.showWindow(nil)
        settingsWindow?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
