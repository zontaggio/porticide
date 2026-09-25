/// Decides which entries are worth showing: by default, only dev servers the
/// current user started from a project folder, hiding macOS system services.
public struct PortFilter: Sendable {
    public var includeSystemProcesses: Bool
    public var currentUser: String
    public var homeDirectory: String

    public init(includeSystemProcesses: Bool, currentUser: String, homeDirectory: String) {
        self.includeSystemProcesses = includeSystemProcesses
        self.currentUser = currentUser
        self.homeDirectory = homeDirectory
    }

    /// Filters `entries` and keeps a single entry per port.
    public func apply(to entries: [PortEntry]) -> [PortEntry] {
        var seenPorts = Set<Int>()
        return entries.filter { entry in
            guard includeSystemProcesses || isUserProcess(entry) else { return false }
            return seenPorts.insert(entry.port).inserted
        }
    }

    func isUserProcess(_ entry: PortEntry) -> Bool {
        if let user = entry.user, user != currentUser { return false }
        if Self.systemProcessNames.contains(where: entry.processName.contains) { return false }

        if let executable = entry.executablePath {
            if Self.isSystemPath(executable) { return false }
            if executable.contains(".app/Contents/Frameworks/") && !executable.hasPrefix(homeDirectory) { return false }
        }

        guard let project = entry.projectPath else {
            // No project folder: only keep binaries that live in the user's home.
            return entry.executablePath.map { $0.hasPrefix(homeDirectory) } ?? true
        }
        return project != "/" && project != homeDirectory && !Self.isSystemPath(project)
    }

    static let systemProcessNames: [String] = [
        "OrbStack", "com.apple", "launchd", "mDNSResponder", "airportd",
        "rapportd", "sharingd", "WiFiAgent", "ControlCenter", "Finder",
        "SystemUIServer", "loginwindow", "WindowServer", "coreduetd",
        "trustd", "cloudd", "apsd", "cfprefsd", "kernel_task",
    ]

    static let systemPathPrefixes = [
        "/System/", "/usr/", "/bin/", "/sbin/", "/private/", "/Library/Apple/", "/Applications/Utilities/",
    ]

    static func isSystemPath(_ path: String) -> Bool {
        systemPathPrefixes.contains { path.hasPrefix($0) }
    }
}
