import Foundation

/// Finds the project a process belongs to, based on its working directory.
public enum ProjectLocator {
    /// Walks up from `directory` to the nearest folder containing `.git`.
    /// Returns `directory` itself when no repository is found.
    public static func projectRoot(for directory: String?) -> String? {
        guard var current = directory, !current.isEmpty else { return nil }
        var isDirectory: ObjCBool = false
        while true {
            let gitPath = (current as NSString).appendingPathComponent(".git")
            if FileManager.default.fileExists(atPath: gitPath, isDirectory: &isDirectory), isDirectory.boolValue {
                return current
            }
            let parent = (current as NSString).deletingLastPathComponent
            if parent == current || parent.isEmpty { return directory }
            current = parent
        }
    }
}
