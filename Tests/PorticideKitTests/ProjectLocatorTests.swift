import Foundation
import Testing
@testable import PorticideKit

struct ProjectLocatorTests {
    @Test func findsNearestGitRoot() throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(atPath: root) }
        try FileManager.default.createDirectory(atPath: "\(root)/.git", withIntermediateDirectories: true)
        try FileManager.default.createDirectory(atPath: "\(root)/apps/web", withIntermediateDirectories: true)

        #expect(ProjectLocator.projectRoot(for: "\(root)/apps/web") == root)
    }

    @Test func recognisesWorktreesWhereGitIsAFile() throws {
        let worktree = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(atPath: worktree) }
        FileManager.default.createFile(atPath: "\(worktree)/.git", contents: Data("gitdir: /elsewhere".utf8))
        try FileManager.default.createDirectory(atPath: "\(worktree)/src", withIntermediateDirectories: true)

        #expect(ProjectLocator.projectRoot(for: "\(worktree)/src") == worktree)
    }

    @Test func fallsBackToWorkingDirectoryOutsideRepositories() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(atPath: directory) }

        #expect(ProjectLocator.projectRoot(for: directory) == directory)
    }

    @Test func returnsNilWithoutWorkingDirectory() {
        #expect(ProjectLocator.projectRoot(for: nil) == nil)
    }

    private func makeTemporaryDirectory() throws -> String {
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent("porticide-\(UUID().uuidString)")
            .resolvingSymlinksInPath()
            .path
        try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
        return path
    }
}
