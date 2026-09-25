import Darwin

/// Looks up details about a running process straight from the kernel, without
/// spawning `ps` or `lsof`. Lookups fail (return nil) for processes owned by
/// other users.
public enum ProcessInspector {
    public static func executablePath(pid: Int32) -> String? {
        var buffer = [UInt8](repeating: 0, count: Int(MAXPATHLEN) * 4)
        let length = proc_pidpath(pid, &buffer, UInt32(buffer.count))
        guard length > 0 else { return nil }
        return String(decoding: buffer.prefix(Int(length)), as: UTF8.self)
    }

    /// The parent process and its name, e.g. a `nodemon` or `pm2` that restarts its children.
    public static func parent(of pid: Int32) -> (pid: Int32, name: String)? {
        var info = proc_bsdinfo()
        let size = Int32(MemoryLayout<proc_bsdinfo>.size)
        guard proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &info, size) == size else { return nil }
        let parent = Int32(bitPattern: info.pbi_ppid)
        var name = [UInt8](repeating: 0, count: Int(MAXCOMLEN) * 2 + 1)
        let length = proc_name(parent, &name, UInt32(name.count))
        guard length > 0 else { return (parent, "") }
        return (parent, String(decoding: name.prefix(Int(length)), as: UTF8.self))
    }

    public static func workingDirectory(pid: Int32) -> String? {
        var info = proc_vnodepathinfo()
        let size = Int32(MemoryLayout<proc_vnodepathinfo>.size)
        guard proc_pidinfo(pid, PROC_PIDVNODEPATHINFO, 0, &info, size) == size else { return nil }
        return withUnsafeBytes(of: info.pvi_cdir.vip_path) { bytes in
            let path = bytes.prefix { $0 != 0 }
            return path.isEmpty ? nil : String(decoding: path, as: UTF8.self)
        }
    }

    /// The process arguments joined by spaces, read via `KERN_PROCARGS2`.
    public static func commandLine(pid: Int32) -> String? {
        guard let arguments = arguments(pid: pid), !arguments.isEmpty else { return nil }
        return arguments.joined(separator: " ")
    }

    /// `KERN_PROCARGS2` layout: `argc` (Int32), the executable path, NUL padding,
    /// then `argc` NUL-terminated arguments followed by the environment.
    static func arguments(pid: Int32) -> [String]? {
        var mib: [Int32] = [CTL_KERN, KERN_PROCARGS2, pid]
        var size = maxArgumentsSize
        var buffer = [UInt8](repeating: 0, count: size)
        guard sysctl(&mib, UInt32(mib.count), &buffer, &size, nil, 0) == 0,
              size > MemoryLayout<Int32>.size else { return nil }

        let argc = buffer.withUnsafeBytes { $0.loadUnaligned(as: Int32.self) }
        var index = MemoryLayout<Int32>.size
        while index < size, buffer[index] != 0 { index += 1 }
        while index < size, buffer[index] == 0 { index += 1 }

        var arguments: [String] = []
        while arguments.count < argc, index < size {
            let start = index
            while index < size, buffer[index] != 0 { index += 1 }
            arguments.append(String(decoding: buffer[start..<index], as: UTF8.self))
            index += 1
        }
        return arguments
    }

    private static let maxArgumentsSize: Int = {
        var mib: [Int32] = [CTL_KERN, KERN_ARGMAX]
        var value: Int32 = 0
        var size = MemoryLayout<Int32>.size
        guard sysctl(&mib, UInt32(mib.count), &value, &size, nil, 0) == 0 else { return 1 << 18 }
        return Int(value)
    }()
}
