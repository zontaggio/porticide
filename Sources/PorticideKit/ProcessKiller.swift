import Darwin

public enum ProcessKiller {
    /// Sends SIGTERM (or SIGKILL when `force` is set) to `pid`. Returns whether the signal was delivered.
    @discardableResult
    public static func terminate(pid: Int32, force: Bool) -> Bool {
        kill(pid, force ? SIGKILL : SIGTERM) == 0
    }
}
