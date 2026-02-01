import Foundation

struct PortEntry: Identifiable, Hashable {
    let id: String
    let port: Int
    let pid: Int
    let processName: String
    let command: String
    let commandLine: String?
    let user: String?
    let protocolType: String?
    let path: String?
    let projectPath: String?
    let startedAt: Date?

    init(port: Int, pid: Int, processName: String, command: String, commandLine: String?, user: String?, protocolType: String?, path: String?, projectPath: String?, startedAt: Date?) {
        self.port = port
        self.pid = pid
        self.processName = processName
        self.command = command
        self.commandLine = commandLine
        self.user = user
        self.protocolType = protocolType
        self.path = path
        self.projectPath = projectPath
        self.startedAt = startedAt
        self.id = "\(port)-\(pid)"
    }
}
// Define basic port entry structure
