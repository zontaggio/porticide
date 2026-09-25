import Darwin
import Foundation
import Testing
@testable import PorticideKit

struct ProcessInspectorTests {
    @Test func readsArgumentsOfCurrentProcess() throws {
        let arguments = try #require(ProcessInspector.arguments(pid: getpid()))
        #expect(arguments == CommandLine.arguments)
    }

    @Test func readsWorkingDirectoryOfCurrentProcess() throws {
        let workingDirectory = try #require(ProcessInspector.workingDirectory(pid: getpid()))
        // The kernel reports /private/tmp where Foundation may say /tmp: compare canonical paths.
        #expect(canonical(workingDirectory) == canonical(FileManager.default.currentDirectoryPath))
    }

    @Test func returnsNilForMissingProcess() {
        let missing: Int32 = 99_999_999
        #expect(ProcessInspector.executablePath(pid: missing) == nil)
        #expect(ProcessInspector.workingDirectory(pid: missing) == nil)
        #expect(ProcessInspector.commandLine(pid: missing) == nil)
    }

    private func canonical(_ path: String) -> String {
        URL(fileURLWithPath: path).resolvingSymlinksInPath().path
    }
}
