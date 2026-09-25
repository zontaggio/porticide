import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settings = SettingsStore()
    private lazy var monitor = PortMonitor(settings: settings)
    private var statusItem: NSStatusItem?
    private var popover = NSPopover()
    private var settingsWindow: SettingsWindowController?
    private var viewModel: PortListViewModel?

    nonisolated func applicationDidFinishLaunching(_ notification: Notification) {
        Task { @MainActor in
            setupUI()
        }
    }
    
    private func setupUI() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            if let logo = AppAssets.logo?.copy() as? NSImage {
                logo.size = NSSize(width: 18, height: 18)
                button.image = logo
            } else {
                button.title = "🔪"
            }
            button.action = #selector(togglePopover)
            button.target = self
        }

        let viewModel = PortListViewModel(settings: settings, monitor: monitor, onOpenSettings: { [weak self] in
            self?.openSettings()
        }, onQuit: { [weak self] in
            self?.quitApp()
        })
        self.viewModel = viewModel
        viewModel.bindSettings()

        let popoverView = PopoverView(viewModel: viewModel)
        popover.contentViewController = NSHostingController(rootView: popoverView)
        popover.behavior = .transient

        settings.onChange = { [weak self] in
            self?.monitor.start()
            self?.viewModel?.bindSettings()
        }

        monitor.onUpdate = { [weak self] entries in
            self?.viewModel?.update(entries: entries)
        }

        monitor.start()
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
        if settingsWindow == nil {
            settingsWindow = SettingsWindowController(settings: settings)
        }
        settingsWindow?.showWindow(nil)
        settingsWindow?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func quitApp() {
        NSApp.terminate(nil)
    }
}
