import Darwin
import Foundation

/// Looks up details about a running process.
public enum ProcessInspector {
    public static func executablePath(pid: Int32) -> String? {
        var buffer = [UInt8](repeating: 0, count: Int(MAXPATHLEN) * 4)
        let length = proc_pidpath(pid, &buffer, UInt32(buffer.count))
        guard length > 0 else { return nil }
        return String(decoding: buffer.prefix(Int(length)), as: UTF8.self)
    }

    public static func commandLine(pid: Int32) -> String? {
        let output = CommandRunner.run("/bin/ps", arguments: ["-p", "\(pid)", "-o", "command="])
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    public static func workingDirectory(pid: Int32) -> String? {
        let output = CommandRunner.run("/usr/sbin/lsof", arguments: ["-p", "\(pid)", "-d", "cwd", "-Fn"])
        for line in output.split(whereSeparator: \.isNewline) where line.hasPrefix("n") {
            let path = line.dropFirst()
            return path.isEmpty ? nil : String(path)
        }
        return nil
    }
}
