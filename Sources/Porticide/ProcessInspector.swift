import Foundation

enum ProcessInspector {
    static func commandLine(pid: Int) -> String? {
        let output = runProcess(path: "/bin/ps", arguments: ["-p", "\(pid)", "-o", "command="])
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    static func currentWorkingDirectory(pid: Int) -> String? {
        let output = runProcess(path: "/usr/sbin/lsof", arguments: ["-p", "\(pid)", "-d", "cwd", "-Fn"])
        for line in output.split(whereSeparator: \.isNewline) {
            if line.hasPrefix("n") {
                let path = line.dropFirst()
                return path.isEmpty ? nil : String(path)
            }
        }
        return nil
    }

    private static func runProcess(path: String, arguments: [String]) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }
}
