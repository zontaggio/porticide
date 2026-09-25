/// Parses the field output of `lsof -F cLPn` (see `PortScanner.lsofArguments`).
///
/// Field mode prints one field per line, prefixed by a single character: a process
/// set (`p` pid, `c` command, `L` login) followed by one file set per socket
/// (`f` descriptor, `P` protocol, `n` address). Unlike the tabular output, it
/// doesn't truncate command names and needs no column guessing.
public enum LsofParser {
    public static func parse(_ output: String, portRange: ClosedRange<Int>) -> [ListeningSocket] {
        var sockets: [ListeningSocket] = []
        var process: (pid: Int32, command: String, user: String?)?
        var file: (transport: String?, address: String?) = (nil, nil)

        func flushFile() {
            defer { file = (nil, nil) }
            guard let process,
                  let transport = file.transport.flatMap(ListeningSocket.Transport.init(rawValue:)),
                  let port = file.address.flatMap(port(fromAddress:)),
                  portRange.contains(port) else { return }
            sockets.append(ListeningSocket(
                port: port,
                pid: process.pid,
                processName: process.command,
                user: process.user,
                transport: transport
            ))
        }

        for line in output.split(whereSeparator: \.isNewline) {
            guard let field = line.first else { continue }
            let value = String(line.dropFirst())
            switch field {
            case "p":
                flushFile()
                process = Int32(value).map { (pid: $0, command: "", user: nil) }
            case "c":
                process?.command = value
            case "L":
                process?.user = value.isEmpty ? nil : value
            case "f":
                flushFile()
            case "P":
                file.transport = value
            case "n":
                file.address = value
            default:
                continue
            }
        }
        flushFile()

        return sockets
    }

    /// Extracts the local port from addresses like `*:3000`, `127.0.0.1:8000`,
    /// `[::1]:5432` or `127.0.0.1:5000->127.0.0.1:6000`.
    static func port(fromAddress address: String) -> Int? {
        let local = address.split(separator: "->", maxSplits: 1).first ?? ""
        guard let separator = local.lastIndex(of: ":") else { return nil }
        return Int(local[local.index(after: separator)...])
    }
}
