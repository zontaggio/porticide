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

        // Started from a project folder: a dev server, whatever runs it (the system
        // Python or Ruby, a `go run` binary in a temporary folder...).
        if let project = entry.projectPath, project != "/", project != homeDirectory, !Self.isSystemPath(project) {
            return true
        }

        if let executable = entry.executablePath {
            if Self.isSystemPath(executable) { return false }
            if executable.contains(".app/Contents/Frameworks/") && !executable.hasPrefix(homeDirectory) { return false }
        }

        // Not started from a project (e.g. `brew services`): keep services Porticide
        // recognises and anything the user installed themselves.
        if entry.service.kind != .other { return true }
        guard let executable = entry.executablePath else { return entry.projectPath == nil }
        return executable.hasPrefix(homeDirectory) || Self.userInstallPrefixes.contains { executable.hasPrefix($0) }
    }

    static let systemProcessNames: [String] = [
        "OrbStack", "com.apple", "launchd", "mDNSResponder", "airportd",
        "rapportd", "sharingd", "WiFiAgent", "ControlCenter", "Finder",
        "SystemUIServer", "loginwindow", "WindowServer", "coreduetd",
        "trustd", "cloudd", "apsd", "cfprefsd", "kernel_task",
    ]

    /// `/usr/local` is deliberately absent: it's where Homebrew (Intel) and
    /// the official Node.js installer put user-installed tools.
    static let systemPathPrefixes = [
        "/System/", "/usr/bin/", "/usr/sbin/", "/usr/libexec/", "/bin/", "/sbin/",
        "/private/", "/Library/Apple/", "/Applications/Utilities/",
    ]

    /// Homebrew (Apple silicon and Intel) and MacPorts.
    static let userInstallPrefixes = ["/opt/homebrew/", "/usr/local/", "/opt/local/"]

    static func isSystemPath(_ path: String) -> Bool {
        systemPathPrefixes.contains { path.hasPrefix($0) }
    }
}
