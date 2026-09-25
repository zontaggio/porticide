import AppKit
import Combine
import PorticideKit

@MainActor
final class PortListViewModel: ObservableObject {
    struct Section: Identifiable {
        let id: String
        let title: String
        /// Container groups show a box next to their title.
        let isContainerGroup: Bool
        let entries: [PortEntry]
    }

    @Published private(set) var entries: [PortEntry] = []
    @Published private(set) var isScanning = true
    /// When each stopped entry started its exit animation.
    @Published private(set) var stopStarts: [PortEntry.ID: Date] = [:]
    /// A message shown inside the popover (never a modal alert, which would close it).
    @Published private(set) var notice: Notice?

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
    /// Recently stopped processes by port, to notice when something restarts them.
    private var recentlyStopped: [Int: (entry: PortEntry, at: Date)] = [:]
    private var noticeDismissal: Task<Void, Never>?
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

    /// Dev servers first, then one group per Compose project, then databases and services.
    var sections: [Section] {
        struct Key: Hashable, Comparable {
            let rank: Int
            let title: String
            let isContainerGroup: Bool
            static func < (lhs: Key, rhs: Key) -> Bool { (lhs.rank, lhs.title) < (rhs.rank, rhs.title) }
        }
        func key(for entry: PortEntry) -> Key {
            if let container = entry.container {
                return Key(rank: 1, title: container.composeProject ?? "Containers", isContainerGroup: true)
            }
            let category = entry.service.kind.category
            let rank = category == .web ? 0 : category.rawValue + 1
            return Key(rank: rank, title: category.title, isContainerGroup: false)
        }
        return Dictionary(grouping: entries, by: key)
            .sorted { $0.key < $1.key }
            .map { Section(id: "\($0.key.rank)-\($0.key.title)", title: $0.key.title, isContainerGroup: $0.key.isContainerGroup, entries: $0.value) }
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
        detectRestarts(in: entries)
        applyFilter()
    }

    /// A stopped server that reappears on its port within seconds, under a new PID, is
    /// being restarted by a supervisor (nodemon, pm2, a shell loop…). Say so, and offer
    /// to stop the supervisor instead.
    private func detectRestarts(in entries: [PortEntry]) {
        let now = Date()
        recentlyStopped = recentlyStopped.filter { now.timeIntervalSince($0.value.at) < 15 }
        for entry in entries {
            guard let stopped = recentlyStopped[entry.port],
                  stopped.entry.processName == entry.processName,
                  stopped.entry.pid != entry.pid else { continue }
            recentlyStopped[entry.port] = nil

            let name = entry.service.displayName
            if let parent = ProcessInspector.parent(of: entry.pid), parent.pid > 1, !parent.name.isEmpty {
                show(Notice(
                    style: .info,
                    title: "\(name) restarted on :\(entry.port)",
                    message: "\(parent.name) (PID \(parent.pid)) brought it back.",
                    action: Notice.Action(title: "Stop \(parent.name)") { [weak self] in
                        self?.stopSupervisor(pid: parent.pid, name: parent.name)
                    }
                ))
            } else {
                show(Notice(
                    style: .info,
                    title: "\(name) restarted on :\(entry.port)",
                    message: "Something outside Porticide keeps it running."
                ))
            }
        }
    }

    private func stopSupervisor(pid: Int32, name: String) {
        do throws(ProcessKiller.Failure) {
            try ProcessKiller.terminate(pid: pid, force: false)
            dismissNotice()
            monitor.refresh()
        } catch {
            show(Notice(style: .warning, title: "Couldn't stop \(name)", message: Self.describe(error, pid: pid)))
        }
    }

    private func applyFilter() {
        let now = Date()
        let live = Set(allEntries.map(\.id))
        // Forget dismissed entries once they're really gone, or after a grace period
        // (a process that ignores SIGTERM should come back into view).
        // 15 s leaves room for `docker stop`, which waits up to 10 s for a container to exit.
        dismissed = dismissed.filter { live.contains($0.key) && now.timeIntervalSince($0.value) < 15 }

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

    /// Stops right away. When "Ask before stopping" is on, the row and the Stop All
    /// button ask for a second click inline before calling this.
    func stop(_ entry: PortEntry, force: Bool) {
        terminate([entry], force: force)
    }

    func stopAll() {
        terminate(entries, force: false)
    }

    /// Starts the exit animation right away and stops the processes in the background;
    /// rows whose process couldn't be stopped snap back.
    private func terminate(_ targets: [PortEntry], force: Bool) {
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
            for entry in stopped where entry.launchdLabel == nil {
                recentlyStopped[entry.port] = (entry, Date())
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
            copyPID: { Self.copy(String(entry.pid)) },
            copyContainerID: { Self.copy(entry.container?.id ?? "") }
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

    // MARK: - Notices

    func dismissNotice() {
        noticeDismissal?.cancel()
        notice = nil
    }

    private func show(_ notice: Notice) {
        self.notice = notice
        noticeDismissal?.cancel()
        noticeDismissal = Task { [weak self] in
            try? await Task.sleep(for: .seconds(8))
            guard !Task.isCancelled else { return }
            self?.notice = nil
        }
    }

    private func showFailures(_ failures: [(PortEntry, ProcessKiller.Failure)]) {
        guard let (entry, failure) = failures.first else { return }
        let title = failures.count == 1
            ? "Couldn't stop \(entry.service.displayName)"
            : "Couldn't stop \(failures.count) processes"
        var action: Notice.Action?
        if case .permissionDenied = failure {
            let command = "sudo kill \(failures.map { String($0.0.pid) }.joined(separator: " "))"
            action = Notice.Action(title: "Copy “\(command)”") { Self.copy(command) }
        }
        show(Notice(style: .warning, title: title, message: Self.describe(failure, pid: entry.pid), action: action))
    }

    private static func describe(_ failure: ProcessKiller.Failure, pid: Int32) -> String {
        switch failure {
        case .permissionDenied: "It belongs to another user, so it needs sudo."
        case .notFound: "PID \(pid) already exited."
        case .serviceControl(let message): "launchd refused: \(message)"
        case .other(let code): String(cString: strerror(code))
        }
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
