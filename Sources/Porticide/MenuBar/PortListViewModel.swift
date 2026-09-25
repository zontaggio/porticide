import AppKit
import PorticideKit

@MainActor
final class PortListViewModel: ObservableObject {
    @Published var entries: [PortEntry] = []
    @Published var showDetailed: Bool
    @Published var isLoading: Bool = true
    @Published var lastUpdated: Date = Date()
    private var rawEntries: [PortEntry] = []

    var portStart: Int { settings.portStart }
    var portEnd: Int { settings.portEnd }

    private let settings: SettingsStore
    private let monitor: PortMonitor
    private let onOpenSettings: () -> Void
    private let onQuit: () -> Void

    init(settings: SettingsStore, monitor: PortMonitor, onOpenSettings: @escaping () -> Void, onQuit: @escaping () -> Void) {
        self.settings = settings
        self.monitor = monitor
        self.onOpenSettings = onOpenSettings
        self.onQuit = onQuit
        self.showDetailed = settings.showDetailed
    }

    func refresh() {
        isLoading = true
        monitor.refresh()
    }

    func updateDetailedSetting() {
        settings.showDetailed = showDetailed
    }

    func update(entries: [PortEntry]) {
        rawEntries = entries
        applyFilters()
        isLoading = false
        lastUpdated = Date()
    }

    func bindSettings() {
        showDetailed = settings.showDetailed
        applyFilters()
    }

    private func applyFilters() {
        let filter = PortFilter(
            includeSystemProcesses: settings.showSystemProcesses,
            currentUser: NSUserName(),
            homeDirectory: NSHomeDirectory()
        )
        entries = filter.apply(to: rawEntries)
    }

    func kill(entry: PortEntry, force: Bool) {
        if settings.confirmBeforeKill {
            let confirmed = confirmKill(entry: entry, force: force)
            if !confirmed { return }
        }
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
        onQuit()
    }

    private func confirmKill(entry: PortEntry, force: Bool) -> Bool {
        let alert = NSAlert()
        alert.messageText = force ? "Force kill process?" : "Kill process?"
        alert.informativeText = "\(entry.service.displayName) (PID \(entry.pid)) on port \(entry.port)."
        alert.addButton(withTitle: "Kill")
        alert.addButton(withTitle: "Cancel")
        return alert.runModal() == .alertFirstButtonReturn
    }
}
