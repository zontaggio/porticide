import AppKit
import Combine
import PorticideKit

@MainActor
final class PortListViewModel: ObservableObject {
    struct Section {
        let category: ServiceKind.Category
        let entries: [PortEntry]
    }

    @Published private(set) var entries: [PortEntry] = []
    @Published private(set) var isScanning = true
    /// When each stopped entry started its exit animation.
    @Published private(set) var stopStarts: [PortEntry.ID: Date] = [:]

    let settings: SettingsStore
    var portRange: ClosedRange<Int> { settings.portRange }
    /// Freezes the animation clock; used to render screenshots frame by frame.
    var clockOverride: Date?

    private let monitor = PortMonitor()
    private let notifier: KillNotifier?
    private let onOpenSettings: () -> Void
    private var allEntries: [PortEntry] = []
    /// Entries already animated away, hidden until a scan confirms they're gone.
    private var dismissed: [PortEntry.ID: Date] = [:]
    private var cancellables: Set<AnyCancellable> = []

    init(settings: SettingsStore, notifier: KillNotifier?, onOpenSettings: @escaping () -> Void) {
        self.settings = settings
        self.notifier = notifier
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

    // MARK: - Derived state

    var sections: [Section] {
        Dictionary(grouping: entries, by: \.service.kind.category)
            .sorted { $0.key < $1.key }
            .map { Section(category: $0.key, entries: $0.value) }
    }

    var statusText: String {
        let running = entries.count - stopStarts.count
        switch running {
        case _ where isScanning && entries.isEmpty: return "Scanning…"
        case ...0: return "No busy ports"
        case 1: return "1 busy port"
        default: return "\(running) busy ports"
        }
    }

    var isAnimatingStops: Bool { !stopStarts.isEmpty }

    func stopProgress(for id: PortEntry.ID, at date: Date) -> Double {
        guard let start = stopStarts[id] else { return 0 }
        return StopEffect.progress(startedAt: start, now: clockOverride ?? date)
    }

    // MARK: - Scanning

    func start() {
        applyFilter()
        monitor.start(portRange: settings.portRange, interval: settings.effectiveRefreshInterval)
    }

    func refresh() {
        monitor.refresh()
    }

    /// Shows fixed entries without scanning; used for screenshots.
    func showDemo(_ entries: [PortEntry]) {
        monitor.stop()
        receive(entries)
    }

    #if DEBUG
    /// Puts an entry mid-animation without stopping anything; used for screenshots.
    func previewStop(_ id: PortEntry.ID, startedAt start: Date) {
        stopStarts[id] = start
    }
    #endif

    private func receive(_ entries: [PortEntry]) {
        allEntries = entries
        isScanning = false
        applyFilter()
    }

    private func applyFilter() {
        let now = Date()
        let live = Set(allEntries.map(\.id))
        // Forget dismissed entries once they're really gone, or after a grace period
        // (a process that ignores SIGTERM should come back into view).
        dismissed = dismissed.filter { live.contains($0.key) && now.timeIntervalSince($0.value) < 5 }

        let filter = PortFilter(
            includeSystemProcesses: settings.showSystemProcesses,
            currentUser: NSUserName(),
            homeDirectory: NSHomeDirectory()
        )
        var visible = filter.apply(to: allEntries).filter { dismissed[$0.id] == nil }
        // Keep rows that are mid-animation even if their process already exited.
        let animating = entries.filter { stopStarts[$0.id] != nil && !visible.contains($0) }
        visible += animating
        visible.sort { $0.port < $1.port }

        if visible != entries {
            entries = visible
        }
    }

    // MARK: - Stopping

    func stop(_ entry: PortEntry, force: Bool) {
        guard stopStarts[entry.id] == nil else { return }
        if settings.confirmBeforeKill {
            let title = force ? "Force quit \(entry.service.displayName)?" : "Stop \(entry.service.displayName)?"
            guard confirm(title, detail: "PID \(entry.pid) on port \(entry.port).", button: force ? "Force Quit" : "Stop") else { return }
        }
        terminate([entry], force: force)
    }

    func stopAll() {
        let targets = entries.filter { stopStarts[$0.id] == nil }
        guard !targets.isEmpty else { return }
        if settings.confirmBeforeKill {
            let list = targets.map { "\($0.service.displayName) on :\($0.port)" }.joined(separator: "\n")
            guard confirm("Stop \(targets.count) processes?", detail: list, button: "Stop All") else { return }
        }
        terminate(targets, force: false)
    }

    /// Starts the exit animation right away and stops the processes in the background;
    /// rows whose process couldn't be stopped snap back.
    private func terminate(_ targets: [PortEntry], force: Bool) {
        // A row may have started stopping while a confirmation dialog was open.
        let targets = targets.filter { stopStarts[$0.id] == nil }
        guard !targets.isEmpty else { return }
        animateStop(targets)

        Task {
            var stopped: [PortEntry] = []
            var failures: [(PortEntry, ProcessKiller.Failure)] = []
            for entry in targets {
                do throws(ProcessKiller.Failure) {
                    try await ProcessKiller.stop(entry, force: force)
                    stopped.append(entry)
                } catch .notFound {
                    stopped.append(entry) // Already gone, which is what the user wanted.
                } catch {
                    failures.append((entry, error))
                }
            }

            for (entry, _) in failures {
                stopStarts[entry.id] = nil
            }
            if settings.showNotifications {
                notifier?.notifyStopped(stopped)
            }
            if !failures.isEmpty {
                showFailures(failures)
            }
        }
    }

    /// Starts the slash animation on each row, cascading when several stop at once,
    /// then removes the rows once they have collapsed.
    private func animateStop(_ stopped: [PortEntry]) {
        guard !stopped.isEmpty else { return }
        let now = Date()
        let stagger = 0.07
        var starts: [PortEntry.ID: Date] = [:]
        for (index, entry) in stopped.enumerated() {
            starts[entry.id] = now.addingTimeInterval(Double(index) * stagger)
        }
        stopStarts.merge(starts) { _, new in new }
        Feedback.play(sound: settings.playSounds)

        let total = StopEffect.duration + Double(stopped.count - 1) * stagger
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(total + 0.05))
            guard let self else { return }
            for (id, start) in starts where stopStarts[id] == start {
                stopStarts[id] = nil
                dismissed[id] = Date()
            }
            applyFilter()
            monitor.refresh()
        }
    }

    // MARK: - Row actions

    func actions(for entry: PortEntry) -> PortRowActions {
        let url = URL(string: "http://localhost:\(entry.port)")!
        let project = entry.projectPath.map { URL(fileURLWithPath: $0, isDirectory: true) }
        return PortRowActions(
            stop: { [weak self] force in self?.stop(entry, force: force) },
            openInBrowser: { NSWorkspace.shared.open(url) },
            copyURL: { Self.copy(url.absoluteString) },
            revealProject: {
                guard let project else { return }
                NSWorkspace.shared.activateFileViewerSelecting([project])
            },
            openTerminal: {
                guard let project,
                      let terminal = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Terminal") else { return }
                NSWorkspace.shared.open([project], withApplicationAt: terminal, configuration: NSWorkspace.OpenConfiguration())
            },
            copyPID: { Self.copy(String(entry.pid)) }
        )
    }

    func openSettings() {
        onOpenSettings()
    }

    func quit() {
        NSApp.terminate(nil)
    }

    private static func copy(_ string: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
    }

    // MARK: - Alerts

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
            case .serviceControl(let message):
                "launchd couldn't stop \(entry.launchdLabel ?? "the service"): \(message)"
            case .other(let code):
                "PID \(entry.pid): \(String(cString: strerror(code)))."
            }
        }.joined(separator: "\n")
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}

/// Sound and trackpad haptics for a stop.
@MainActor
private enum Feedback {
    static func play(sound: Bool) {
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
        guard sound, let pop = NSSound(named: "Pop")?.copy() as? NSSound else { return }
        pop.volume = 0.35
        pop.play()
    }
}
