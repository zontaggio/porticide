import Foundation

/// Parses the tabular output of `lsof -n -P -iTCP -sTCP:LISTEN -iUDP`.
public enum LsofParser {
    public static func parse(_ output: String, portRange: ClosedRange<Int>) -> [ListeningSocket] {
        let lines = output.split(whereSeparator: \.isNewline)
        guard lines.count > 1 else { return [] }

        var sockets: [ListeningSocket] = []
        for line in lines.dropFirst() {
            let parts = line.split(whereSeparator: { $0 == " " || $0 == "\t" }).map(String.init)
            guard parts.count >= 9 else { continue }

            let command = parts[0]
            guard let pid = Int32(parts[1]) else { continue }
            let user = parts[2]
            guard let transport = ListeningSocket.Transport(rawValue: parts[7]) else { continue }
            guard let port = parsePort(from: parts[8]) else { continue }
            guard portRange.contains(port) else { continue }

            sockets.append(ListeningSocket(
                port: port,
                pid: pid,
                processName: command,
                user: user.isEmpty ? nil : user,
                transport: transport
            ))
        }

        return sockets
    }

    private static func parsePort(from address: String) -> Int? {
        let regex = try? NSRegularExpression(pattern: ":(\\d+)", options: [])
        let range = NSRange(address.startIndex..<address.endIndex, in: address)
        guard let match = regex?.firstMatch(in: address, options: [], range: range) else { return nil }
        guard let portRange = Range(match.range(at: 1), in: address) else { return nil }
        return Int(address[portRange])
    }
}
