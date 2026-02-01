import Foundation

final class PortMonitor: @unchecked Sendable {
    private let settings: SettingsStore
    private let queue = DispatchQueue(label: "porticide.monitor", qos: .userInitiated)
    private var timer: DispatchSourceTimer?

    var onUpdate: (([PortEntry]) -> Void)?
    var onError: ((Error) -> Void)?

    init(settings: SettingsStore) {
        self.settings = settings
    }

    func start() {
        stop()
        scheduleTimer()
        refresh()
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    func refresh() {
        let range = settings.portStart...settings.portEnd
        queue.async { [weak self] in
            guard let self else { return }
            do {
                let output = try self.runLsof()
                var entries = LsofParser.parse(output, portRange: range)
                entries = entries.map { entry in
                    let path = ProcessUtils.processPath(pid: Int32(entry.pid))
                    let commandLine = ProcessInspector.commandLine(pid: entry.pid)
                    let cwd = ProcessInspector.currentWorkingDirectory(pid: entry.pid)
                    let projectRoot = PathUtils.projectRoot(from: cwd)
                    let displayPath = PathUtils.tildePath(projectRoot)
                    let normalizedPath = (displayPath == "/" || displayPath?.isEmpty == true) ? nil : displayPath
                    return PortEntry(
                        port: entry.port,
                        pid: entry.pid,
                        processName: entry.processName,
                        command: entry.command,
                        commandLine: commandLine,
                        user: entry.user,
                        protocolType: entry.protocolType,
                        path: path,
                        projectPath: normalizedPath,
                        startedAt: entry.startedAt
                    )
                }
                entries.sort { $0.port < $1.port }
                DispatchQueue.main.async {
                    self.onUpdate?(entries)
                }
            } catch {
                DispatchQueue.main.async {
                    self.onError?(error)
                }
            }
        }
    }

    private func scheduleTimer() {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + 0.1, repeating: settings.refreshInterval)
        timer.setEventHandler { [weak self] in
            self?.refresh()
        }
        timer.resume()
        self.timer = timer
    }

    private func runLsof() throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        process.arguments = ["-n", "-P", "-iTCP", "-sTCP:LISTEN", "-iUDP"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
}
