//
//  RepositoryOperationTests.swift
//
//
//  Created by İbrahim Çetin on 18.06.2024.
//

import Foundation
import SwiftGitX
import Testing

// MARK: - Log

@Suite("Repository - Log", .tags(.repository, .operation, .log))
final class RepositoryLogTests: SwiftGitXTest {
    @Test("Log returns commits in order")
    func log() async throws {
        let repository = mockRepository()

        // Create multiple commits
        let commits = try (0..<10).map { _ in try repository.mockCommit() }

        // Get log with reverse sorting
        let commitSequence = try repository.log(from: repository.HEAD, sorting: .reverse)
        let logCommits = Array(commitSequence)
        #expect(logCommits == commits)
    }
}

// MARK: - Revert

@Suite("Repository - Revert", .tags(.repository, .operation, .revert))
final class RepositoryRevertTests: SwiftGitXTest {
    @Test("Revert commit")
    func revert() async throws {
        let repository = mockRepository()

        // Create initial commit with file
        let file1 = try repository.mockFile()
        try repository.mockCommit(file: file1)

        // Modify and commit
        try Data("Revert me!".utf8).write(to: file1)
        let commitToRevert = try repository.mockCommit(file: file1)

        // Revert
        try repository.revert(commitToRevert)

        // File should be staged with original content
        #expect(try repository.status(file: file1) == [.indexModified])
        #expect(try String(contentsOf: file1) == "File 1 content\n")
    }
}
