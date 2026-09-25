import Foundation

/// Lists processes listening on local ports and resolves what they are.
public struct PortScanner: Sendable {
    /// Numeric hosts and ports (`-nP`), listening TCP and all UDP sockets, machine-readable fields.
    static let lsofArguments = ["-nP", "-iTCP", "-sTCP:LISTEN", "-iUDP", "-F", "cLPn"]

    public init() {}

    public func scan(portRange: ClosedRange<Int>) -> [PortEntry] {
        let output = CommandRunner.run("/usr/sbin/lsof", arguments: Self.lsofArguments)
        return LsofParser.parse(output, portRange: portRange)
            .map(enrich)
            .sorted { $0.port < $1.port }
    }

    private func enrich(_ socket: ListeningSocket) -> PortEntry {
        let commandLine = ProcessInspector.commandLine(pid: socket.pid)
        let projectRoot = ProjectLocator.projectRoot(for: ProcessInspector.workingDirectory(pid: socket.pid))
        return PortEntry(
            socket: socket,
            executablePath: ProcessInspector.executablePath(pid: socket.pid),
            commandLine: commandLine,
            projectPath: projectRoot == "/" ? nil : projectRoot,
            service: ServiceClassifier.classify(commandLine: commandLine, processName: socket.processName)
        )
    }
}
