import Foundation

enum CommandRunner {
    /// Runs an executable off the cooperative thread pool and returns its standard
    /// output, or an empty string if it can't be launched.
    static func run(_ path: String, arguments: [String]) async -> String {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                continuation.resume(returning: runBlocking(path, arguments: arguments))
            }
        }
    }

    private static func runBlocking(_ path: String, arguments: [String]) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments

        let stdout = Pipe()
        process.standardOutput = stdout
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
        } catch {
            return ""
        }
        // Drain the pipe before waiting, or a large output fills its buffer and deadlocks.
        let data = stdout.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return String(decoding: data, as: UTF8.self)
    }
}
