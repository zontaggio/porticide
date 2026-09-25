import AppKit
import Combine
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
    private var cancellables: Set<AnyCancellable> = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        setUpStatusItem()

        let hostingController = NSHostingController(rootView: PopoverView(viewModel: viewModel, settings: settings))
        hostingController.sizingOptions = .preferredContentSize
        popover.contentViewController = hostingController
        popover.behavior = .transient
        popover.animates = true

        // Show how many ports are busy next to the menu bar icon.
        viewModel.$entries.combineLatest(viewModel.$stopStarts, settings.$showCountInMenuBar)
            .map { entries, stopping, showCount in showCount ? entries.count - stopping.count : 0 }
            .removeDuplicates()
            .sink { [weak self] count in self?.updateCount(count) }
            .store(in: &cancellables)

        viewModel.start()
    }

    private func setUpStatusItem() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = MenuBarIcon.image
            button.action = #selector(togglePopover)
            button.target = self
        }
        self.statusItem = statusItem
    }

    private func updateCount(_ count: Int) {
        guard let button = statusItem?.button else { return }
        button.imagePosition = .imageLeading
        button.attributedTitle = count > 0
            ? NSAttributedString(string: " \(count)", attributes: [.font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .semibold)])
            : NSAttributedString()
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            viewModel.refresh()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
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
