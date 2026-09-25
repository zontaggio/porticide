import Foundation

enum CommandRunner {
    struct Output: Sendable {
        var status: Int32
        var stdout: String
        var stderr: String
    }

    /// Runs an executable off the cooperative thread pool. A command that can't be
    /// launched reports status -1 and empty output.
    static func run(_ path: String, arguments: [String]) async -> Output {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                continuation.resume(returning: runBlocking(path, arguments: arguments))
            }
        }
    }

    private static func runBlocking(_ path: String, arguments: [String]) -> Output {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        do {
            try process.run()
        } catch {
            return Output(status: -1, stdout: "", stderr: error.localizedDescription)
        }
        // Drain the pipes before waiting, or a large output fills their buffers and deadlocks.
        let output = stdout.fileHandleForReading.readDataToEndOfFile()
        let errors = stderr.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return Output(
            status: process.terminationStatus,
            stdout: String(decoding: output, as: UTF8.self),
            stderr: String(decoding: errors, as: UTF8.self)
        )
    }
}
