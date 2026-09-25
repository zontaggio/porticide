import Foundation
import Testing
@testable import PorticideKit

struct ProcessKillerTests {
    @Test func terminatesChildProcess() throws {
        let sleeper = Process()
        sleeper.executableURL = URL(fileURLWithPath: "/bin/sleep")
        sleeper.arguments = ["30"]
        try sleeper.run()

        try ProcessKiller.terminate(pid: sleeper.processIdentifier, force: false)
        sleeper.waitUntilExit()

        #expect(sleeper.terminationReason == .uncaughtSignal)
        #expect(sleeper.terminationStatus == SIGTERM)
    }

    @Test func reportsMissingProcess() {
        #expect(throws: ProcessKiller.Failure.notFound) {
            try ProcessKiller.terminate(pid: 99_999_999, force: false)
        }
    }

    @Test func reportsPermissionDeniedForSystemProcess() {
        // launchd (PID 1) is owned by root.
        #expect(throws: ProcessKiller.Failure.permissionDenied) {
            try ProcessKiller.terminate(pid: 1, force: false)
        }
    }
}
