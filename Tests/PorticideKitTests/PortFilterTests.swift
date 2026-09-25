import Testing
@testable import PorticideKit

struct PortFilterTests {
    let filter = PortFilter(includeSystemProcesses: false, currentUser: "me", homeDirectory: "/Users/me")

    @Test func keepsDevServerRunningFromProject() {
        let vite = entry(executable: "/Users/me/.nvm/versions/node/v20/bin/node", project: "/Users/me/code/web")
        #expect(filter.apply(to: [vite]) == [vite])
    }

    @Test func hidesOtherUsersProcesses() {
        let other = entry(user: "root", project: "/Users/me/code/web")
        #expect(filter.apply(to: [other]).isEmpty)
    }

    @Test func hidesSystemServices() {
        let controlCenter = entry(
            name: "ControlCenter",
            executable: "/System/Library/CoreServices/ControlCenter.app/Contents/MacOS/ControlCenter"
        )
        #expect(filter.apply(to: [controlCenter]).isEmpty)
    }

    @Test func hidesProcessesRunningFromHomeOrRoot() {
        let fromHome = entry(port: 3000, project: "/Users/me")
        let fromRoot = entry(port: 3001, project: "/")
        #expect(filter.apply(to: [fromHome, fromRoot]).isEmpty)
    }

    @Test func showsEverythingWhenSystemProcessesAreIncluded() {
        var filter = filter
        filter.includeSystemProcesses = true
        let system = entry(name: "rapportd", user: "root", executable: "/usr/libexec/rapportd")
        #expect(filter.apply(to: [system]) == [system])
    }

    @Test func keepsOneEntryPerPort() {
        let ipv4 = entry(port: 3000, pid: 1, project: "/Users/me/code/web")
        let ipv6 = entry(port: 3000, pid: 2, project: "/Users/me/code/web")
        #expect(filter.apply(to: [ipv4, ipv6]) == [ipv4])
    }

    private func entry(
        port: Int = 3000,
        pid: Int32 = 100,
        name: String = "node",
        user: String = "me",
        executable: String? = nil,
        project: String? = nil
    ) -> PortEntry {
        PortEntry(
            socket: ListeningSocket(port: port, pid: pid, processName: name, user: user, transport: .tcp),
            executablePath: executable,
            commandLine: nil,
            projectPath: project,
            service: ServiceInfo(displayName: name, iconName: "terminal")
        )
    }
}
