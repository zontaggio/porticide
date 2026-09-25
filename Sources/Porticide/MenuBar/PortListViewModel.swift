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
        if settings.confirmBeforeKill {
            let title = force ? "Force quit \(entry.service.displayName)?" : "Stop \(entry.service.displayName)?"
            guard confirm(title, detail: "PID \(entry.pid) on port \(entry.port).", button: force ? "Force Quit" : "Stop") else { return }
        }
        terminate([entry], force: force)
    }

    func killAll() {
        guard !entries.isEmpty else { return }
        if settings.confirmBeforeKill {
            let list = entries.map { "\($0.service.displayName) on :\($0.port)" }.joined(separator: "\n")
            guard confirm("Stop \(entries.count) processes?", detail: list, button: "Stop All") else { return }
        }
        terminate(entries, force: false)
    }

    private func terminate(_ targets: [PortEntry], force: Bool) {
        var failures: [(PortEntry, ProcessKiller.Failure)] = []
        for entry in targets {
            do {
                try ProcessKiller.terminate(pid: entry.pid, force: force)
            } catch .notFound {
                continue // Already gone, which is what the user wanted.
            } catch {
                failures.append((entry, error))
            }
        }
        if !failures.isEmpty {
            showFailures(failures)
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

    private func confirm(_ title: String, detail: String, button: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = detail
        alert.addButton(withTitle: button)
        alert.addButton(withTitle: "Cancel")
        NSApp.activate(ignoringOtherApps: true)
        return alert.runModal() == .alertFirstButtonReturn
    }

    private func showFailures(_ failures: [(PortEntry, ProcessKiller.Failure)]) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = failures.count == 1
            ? "Couldn't stop \(failures[0].0.service.displayName)"
            : "Couldn't stop \(failures.count) processes"
        alert.informativeText = failures.map { entry, failure in
            switch failure {
            case .permissionDenied:
                "PID \(entry.pid) belongs to another user. Run `sudo kill \(entry.pid)` in Terminal."
            case .notFound:
                "PID \(entry.pid) already exited."
            case .other(let code):
                "PID \(entry.pid): \(String(cString: strerror(code)))."
            }
        }.joined(separator: "\n")
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}
