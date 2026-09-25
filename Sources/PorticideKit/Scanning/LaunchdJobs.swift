import Darwin

/// Jobs that launchd runs on the user's behalf: LaunchAgents such as `brew services`
/// or background daemons installed by dev tools. With `KeepAlive`, launchd restarts
/// them as soon as they exit, so they have to be stopped through launchd itself.
public enum LaunchdJobs {
    /// Labels of the user's running launchd jobs, keyed by PID.
    public static func running() async -> [Int32: String] {
        parse(await CommandRunner.run("/bin/launchctl", arguments: ["list"]).stdout)
    }

    /// Parses `launchctl list`, whose rows are `PID<TAB>Status<TAB>Label`.
    /// Jobs that aren't running have `-` as their PID and are skipped.
    static func parse(_ output: String) -> [Int32: String] {
        var jobs: [Int32: String] = [:]
        for line in output.split(whereSeparator: \.isNewline) {
            let columns = line.split(separator: "\t", maxSplits: 2)
            guard columns.count == 3, let pid = Int32(columns[0]) else { continue }
            jobs[pid] = String(columns[2])
        }
        return jobs
    }

    /// Stops a job and unloads it for the rest of the login session, so `KeepAlive`
    /// can't bring it back. It loads again at next login, like `brew services stop`
    /// without removing the service.
    public static func bootOut(label: String) async throws(ProcessKiller.Failure) {
        let target = "gui/\(getuid())/\(label)"
        let result = await CommandRunner.run("/bin/launchctl", arguments: ["bootout", target])
        guard result.status == 0 else {
            let message = result.stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            throw .serviceControl(message.isEmpty ? "launchctl bootout exited with status \(result.status)" : message)
        }
    }
}
