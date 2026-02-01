import Foundation

enum LsofParser {
    static func parse(_ output: String, portRange: ClosedRange<Int>) -> [PortEntry] {
        let lines = output.split(whereSeparator: \.isNewline)
        guard lines.count > 1 else { return [] }

        var entries: [PortEntry] = []
        for line in lines.dropFirst() {
            let parts = line.split(whereSeparator: { $0 == " " || $0 == "\t" }).map(String.init)
            guard parts.count >= 9 else { continue }

            let command = parts[0]
            guard let pid = Int(parts[1]) else { continue }
            let user = parts[2]
            let nameField = parts[8...].joined(separator: " ")

            guard let (protocolType, port) = parseProtocolAndPort(from: nameField) else { continue }
            guard portRange.contains(port) else { continue }

            let entry = PortEntry(
                port: port,
                pid: pid,
                processName: command,
                command: command,
                commandLine: nil,
                user: user.isEmpty ? nil : user,
                protocolType: protocolType,
                path: nil,
                projectPath: nil,
                startedAt: nil
            )
            entries.append(entry)
        }

        return entries
    }

    private static func parseProtocolAndPort(from nameField: String) -> (String?, Int)? {
        let proto: String?
        if nameField.contains("TCP") {
            proto = "TCP"
        } else if nameField.contains("UDP") {
            proto = "UDP"
        } else {
            proto = nil
        }

        let regex = try? NSRegularExpression(pattern: ":(\\d+)", options: [])
        let range = NSRange(nameField.startIndex..<nameField.endIndex, in: nameField)
        guard let match = regex?.firstMatch(in: nameField, options: [], range: range) else { return nil }
        guard let portRange = Range(match.range(at: 1), in: nameField) else { return nil }
        guard let port = Int(nameField[portRange]) else { return nil }

        return (proto, port)
    }
}
// Basic lsof output parsing
// TODO: Handle edge cases in parsing
