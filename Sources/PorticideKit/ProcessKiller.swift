import Darwin

public enum ProcessKiller {
    public enum Failure: Error, Equatable, Sendable {
        /// The process belongs to another user (usually root); it needs `sudo kill`.
        case permissionDenied
        /// The process already exited.
        case notFound
        case other(errno: Int32)
    }

    /// Sends SIGTERM, or SIGKILL when `force` is set, to `pid`.
    public static func terminate(pid: Int32, force: Bool) throws(Failure) {
        guard kill(pid, force ? SIGKILL : SIGTERM) != 0 else { return }
        switch errno {
        case EPERM: throw .permissionDenied
        case ESRCH: throw .notFound
        case let code: throw .other(errno: code)
        }
    }
}
