import Foundation

/// Containers whose ports are published on the host by Docker Desktop, OrbStack,
/// Colima or Podman. On macOS those ports are held by the runtime's own process,
/// so stopping that process would take down every container: containers are
/// stopped through the `docker` CLI instead.
public enum Containers {
    /// Processes that hold published container ports on the host.
    static let runtimeProcessNames: Set<String> = [
        "OrbStack", "OrbStack Helper", "com.docker.backend", "com.docker.vpnkit",
        "vpnkit-bridge", "docker-proxy", "gvproxy", "limactl",
    ]

    public static func isRuntime(_ processName: String) -> Bool {
        runtimeProcessNames.contains(processName)
    }

    /// Menu bar apps get a minimal PATH, so look for the CLI where runtimes install it.
    static let dockerCandidates = [
        "/usr/local/bin/docker",
        "/opt/homebrew/bin/docker",
        "\(NSHomeDirectory())/.orbstack/bin/docker",
        "/Applications/OrbStack.app/Contents/MacOS/xbin/docker",
        "/Applications/Docker.app/Contents/Resources/bin/docker",
    ]

    static var dockerPath: String? {
        dockerCandidates.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    /// Running containers with published ports, or an empty list if Docker isn't available.
    public static func running() async -> [Container] {
        guard let docker = dockerPath else { return [] }
        let format = "{{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Label \"com.docker.compose.project\"}}"
        let result = await CommandRunner.run(docker, arguments: ["ps", "--format", format])
        guard result.status == 0 else { return [] }
        return parse(result.stdout)
    }

    /// Parses `docker ps` rows produced by the format in `running()`.
    static func parse(_ output: String) -> [Container] {
        output.split(whereSeparator: \.isNewline).compactMap { line in
            let columns = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
            guard columns.count >= 4 else { return nil }
            let ports = publishedPorts(columns[3])
            guard !ports.isEmpty else { return nil }
            let project = columns.count > 4 && !columns[4].isEmpty ? columns[4] : nil
            return Container(id: columns[0], name: columns[1], image: columns[2], composeProject: project, publishedPorts: ports)
        }
    }

    /// Host ports from a `Ports` column such as
    /// `0.0.0.0:5433->5432/tcp, [::]:5433->5432/tcp, 3002-3003/tcp`.
    /// Exposed-only ports (without `->`) aren't reachable from the host and are skipped.
    static func publishedPorts(_ column: String) -> Set<Int> {
        var ports: Set<Int> = []
        for mapping in column.split(separator: ",") {
            guard let arrow = mapping.range(of: "->") else { continue }
            let host = mapping[..<arrow.lowerBound]
            guard let colon = host.lastIndex(of: ":") else { continue }
            let bounds = host[host.index(after: colon)...].split(separator: "-").compactMap { Int($0) }
            if let low = bounds.first, let high = bounds.last, low <= high {
                ports.formUnion(low...high)
            }
        }
        return ports
    }

    /// `docker stop`, or `docker kill` when forced.
    public static func stop(_ container: Container, force: Bool) async throws(ProcessKiller.Failure) {
        guard let docker = dockerPath else { throw .serviceControl("The docker command wasn't found.") }
        let result = await CommandRunner.run(docker, arguments: [force ? "kill" : "stop", container.id])
        guard result.status == 0 else {
            let message = result.stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            throw .serviceControl(message.isEmpty ? "docker exited with status \(result.status)" : message)
        }
    }
}
