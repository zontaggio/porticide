import Foundation

enum PathUtils {
    static func projectRoot(from path: String?) -> String? {
        guard var current = path else { return nil }
        var isDir: ObjCBool = false
        while !current.isEmpty {
            let gitPath = (current as NSString).appendingPathComponent(".git")
            if FileManager.default.fileExists(atPath: gitPath, isDirectory: &isDir), isDir.boolValue {
                return current
            }
            let parent = (current as NSString).deletingLastPathComponent
            if parent == current { break }
            current = parent
        }
        return path
    }

    static func tildePath(_ path: String?) -> String? {
        guard let path else { return nil }
        let home = NSHomeDirectory()
        if path.hasPrefix(home) {
            return path.replacingOccurrences(of: home, with: "~")
        }
        return path
    }
}
// Utility functions for path handling
// Improve path resolution for project detection
