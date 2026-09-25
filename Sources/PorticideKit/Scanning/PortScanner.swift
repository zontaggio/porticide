import Foundation

/// Lists processes listening on local ports and resolves what they are.
public struct PortScanner: Sendable {
    public init() {}

    public func scan(portRange: ClosedRange<Int>) -> [PortEntry] {
        let output = CommandRunner.run("/usr/sbin/lsof", arguments: ["-n", "-P", "-iTCP", "-sTCP:LISTEN", "-iUDP"])
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
            service: ServiceClassifier.classify(commandLine: commandLine)
        )
    }
}
