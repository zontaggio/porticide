import Foundation
import AppKit

@MainActor
final class AppViewModel: ObservableObject {
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
        let currentUser = NSUserName()
        let home = NSHomeDirectory()
        var filtered = rawEntries.filter { entry in
            if settings.showSystemProcesses { return true }
            if let user = entry.user, user != currentUser { return false }
            if isSystemProcess(entry) { return false }
            if let path = entry.path, isSystemPath(path) { return false }
            if let project = entry.projectPath {
                if project == "/" || project == "~" { return false }
                if isSystemPath(project) { return false }
            }
            // Prefer processes with project paths under home
            if let path = entry.path, !path.hasPrefix(home) && entry.projectPath == nil { return false }
            return true
        }
        // Deduplicate by port (keep first occurrence)
        var seenPorts = Set<Int>()
        filtered = filtered.filter { entry in
            if seenPorts.contains(entry.port) { return false }
            seenPorts.insert(entry.port)
            return true
        }
        entries = filtered
    }

    private static let systemProcessNames: Set<String> = [
        "OrbStack", "com.apple", "launchd", "mDNSResponder", "airportd",
        "rapportd", "sharingd", "WiFiAgent", "ControlCenter", "Finder",
        "SystemUIServer", "loginwindow", "WindowServer", "coreduetd",
        "trustd", "cloudd", "apsd", "cfprefsd", "kernel_task"
    ]

    private func isSystemPath(_ path: String) -> Bool {
        let systemPrefixes = ["/System/", "/usr/", "/bin/", "/sbin/", "/private/", "/Library/Apple/", "/Applications/Utilities/"]
        return systemPrefixes.contains { path.hasPrefix($0) }
    }

    private func isSystemProcess(_ entry: PortEntry) -> Bool {
        if Self.systemProcessNames.contains(where: { entry.processName.contains($0) }) { return true }
        if let path = entry.path, path.contains(".app/Contents/Frameworks/") && !path.contains(NSHomeDirectory()) { return true }
        return false
    }

    func kill(entry: PortEntry, force: Bool) {
        if settings.confirmBeforeKill {
            let confirmed = confirmKill(entry: entry, force: force)
            if !confirmed { return }
        }
        _ = ProcessUtils.terminate(pid: Int32(entry.pid), force: force)
        monitor.refresh()
    }

    func killAll() {
        for entry in entries {
            _ = ProcessUtils.terminate(pid: Int32(entry.pid), force: false)
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
        alert.informativeText = "\(entry.displayName) (PID \(entry.pid)) on port \(entry.port)."
        alert.addButton(withTitle: "Kill")
        alert.addButton(withTitle: "Cancel")
        return alert.runModal() == .alertFirstButtonReturn
    }
}
// Fix: Race condition in process info fetching
// Add proper error handling for permission denied
