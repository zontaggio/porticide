/// Lists processes listening on local ports and resolves what they are.
///
/// Process details are cached per PID between scans, since a server's
/// command line and project don't change while it runs.
public actor PortScanner {
    /// Numeric hosts and ports (`-nP`), listening TCP and all UDP sockets, machine-readable fields.
    static let lsofArguments = ["-nP", "-iTCP", "-sTCP:LISTEN", "-iUDP", "-F", "cLPn"]

    private struct ProcessDetails {
        let processName: String
        let executablePath: String?
        let commandLine: String?
        let projectPath: String?
        let service: ServiceInfo
    }

    private var cache: [Int32: ProcessDetails] = [:]

    public init() {}

    /// Entries sorted by port, TCP before UDP.
    public func scan(portRange: ClosedRange<Int>) async -> [PortEntry] {
        async let lsof = CommandRunner.run("/usr/sbin/lsof", arguments: Self.lsofArguments)
        async let launchdJobs = LaunchdJobs.running()
        let sockets = LsofParser.parse(await lsof.stdout, portRange: portRange)
        let jobs = await launchdJobs

        let livePIDs = Set(sockets.map(\.pid))
        cache = cache.filter { livePIDs.contains($0.key) }

        return sockets
            .map { socket in
                let details = details(for: socket)
                return PortEntry(
                    socket: socket,
                    executablePath: details.executablePath,
                    commandLine: details.commandLine,
                    projectPath: details.projectPath,
                    service: details.service,
                    launchdLabel: jobs[socket.pid]
                )
            }
            .sorted { ($0.port, $0.socket.transport == .tcp ? 0 : 1) < ($1.port, $1.socket.transport == .tcp ? 0 : 1) }
    }

    private func details(for socket: ListeningSocket) -> ProcessDetails {
        // Compare names too, in case the PID was recycled by a new process.
        if let cached = cache[socket.pid], cached.processName == socket.processName {
            return cached
        }
        let commandLine = ProcessInspector.commandLine(pid: socket.pid)
        let projectRoot = ProjectLocator.projectRoot(for: ProcessInspector.workingDirectory(pid: socket.pid))
        let details = ProcessDetails(
            processName: socket.processName,
            executablePath: ProcessInspector.executablePath(pid: socket.pid),
            commandLine: commandLine,
            projectPath: projectRoot == "/" ? nil : projectRoot,
            service: ServiceClassifier.classify(commandLine: commandLine, processName: socket.processName)
        )
        cache[socket.pid] = details
        return details
    }
}
