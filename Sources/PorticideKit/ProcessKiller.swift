import Darwin

public enum ProcessKiller {
    public enum Failure: Error, Equatable, Sendable {
        /// The process belongs to another user (usually root); it needs `sudo kill`.
        case permissionDenied
        /// The process already exited.
        case notFound
        /// launchd refused to stop the job; carries its error message.
        case serviceControl(String)
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

    /// Stops what holds `entry`'s port. Containers are stopped through Docker (killing the
    /// runtime would stop them all), and processes supervised by launchd are booted out of
    /// their job instead of signalled, because launchd would restart them at once.
    public static func stop(_ entry: PortEntry, force: Bool) async throws(Failure) {
        if let container = entry.container {
            try await Containers.stop(container, force: force)
        } else if let label = entry.launchdLabel {
            try await LaunchdJobs.bootOut(label: label)
        } else {
            try terminate(pid: entry.pid, force: force)
        }
    }
}
