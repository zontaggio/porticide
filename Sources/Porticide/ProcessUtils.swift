import Foundation
import Darwin

enum ProcessUtils {
    static func processPath(pid: Int32) -> String? {
        var buffer = [CChar](repeating: 0, count: 4096)
        let result = proc_pidpath(pid, &buffer, UInt32(buffer.count))
        guard result > 0 else { return nil }
        let endIndex = buffer.firstIndex(of: 0) ?? buffer.count
        let slice = buffer[..<endIndex]
        let bytes = slice.map { UInt8(bitPattern: $0) }
        return String(decoding: bytes, as: UTF8.self)
    }

    static func terminate(pid: Int32, force: Bool) -> Bool {
        let signal = force ? SIGKILL : SIGTERM
        return kill(pid, signal) == 0
    }
}
