import AppKit
import Combine
import PorticideKit

@MainActor
final class PortListViewModel: ObservableObject {
    @Published private(set) var entries: [PortEntry] = []
    @Published private(set) var isScanning = true
    @Published private(set) var lastUpdated: Date?

    let settings: SettingsStore
    var portRange: ClosedRange<Int> { settings.portRange }

    private let monitor = PortMonitor()
    private var allEntries: [PortEntry] = []
    private var cancellables: Set<AnyCancellable> = []
    private let onOpenSettings: () -> Void

    init(settings: SettingsStore, onOpenSettings: @escaping () -> Void) {
        self.settings = settings
        self.onOpenSettings = onOpenSettings

        monitor.onUpdate = { [weak self] entries in
            self?.receive(entries)
        }

        // Restart scanning once the user stops typing in the settings window.
        settings.objectWillChange
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.start() }
            .store(in: &cancellables)
    }

    func start() {
        applyFilter()
        monitor.start(portRange: settings.portRange, interval: settings.effectiveRefreshInterval)
    }

    func refresh() {
        isScanning = true
        monitor.refresh()
    }

    func kill(_ entry: PortEntry, force: Bool) {
        if settings.confirmBeforeKill, !confirmKill(entry, force: force) { return }
        ProcessKiller.terminate(pid: entry.pid, force: force)
        monitor.refresh()
    }

    func killAll() {
        for entry in entries {
            ProcessKiller.terminate(pid: entry.pid, force: false)
        }
        monitor.refresh()
    }

    func openSettings() {
        onOpenSettings()
    }

    func quit() {
        NSApp.terminate(nil)
    }

    private func receive(_ entries: [PortEntry]) {
        allEntries = entries
        applyFilter()
        isScanning = false
        lastUpdated = Date()
    }

    private func applyFilter() {
        let filter = PortFilter(
            includeSystemProcesses: settings.showSystemProcesses,
            currentUser: NSUserName(),
            homeDirectory: NSHomeDirectory()
        )
        entries = filter.apply(to: allEntries)
    }

    private func confirmKill(_ entry: PortEntry, force: Bool) -> Bool {
        let alert = NSAlert()
        alert.messageText = force ? "Force kill process?" : "Kill process?"
        alert.informativeText = "\(entry.service.displayName) (PID \(entry.pid)) on port \(entry.port)."
        alert.addButton(withTitle: "Kill")
        alert.addButton(withTitle: "Cancel")
        return alert.runModal() == .alertFirstButtonReturn
    }
}
