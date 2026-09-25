/// A listening socket enriched with details about the process that owns it.
public struct PortEntry: Identifiable, Hashable, Sendable {
    public let socket: ListeningSocket
    /// Absolute path of the process executable.
    public let executablePath: String?
    /// Full command line, including arguments.
    public let commandLine: String?
    /// Root of the project the process runs from (nearest git root of its working directory).
    public let projectPath: String?
    public let service: ServiceInfo
    /// The launchd job that runs this process, if any (e.g. `homebrew.mxcl.postgresql@17`).
    public let launchdLabel: String?

    public init(
        socket: ListeningSocket,
        executablePath: String?,
        commandLine: String?,
        projectPath: String?,
        service: ServiceInfo,
        launchdLabel: String? = nil
    ) {
        self.socket = socket
        self.executablePath = executablePath
        self.commandLine = commandLine
        self.projectPath = projectPath
        self.service = service
        self.launchdLabel = launchdLabel
    }

    public var id: String { "\(socket.transport.rawValue)-\(socket.port)-\(socket.pid)" }
    public var port: Int { socket.port }
    public var pid: Int32 { socket.pid }
    public var processName: String { socket.processName }
    public var user: String? { socket.user }
}
