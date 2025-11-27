//
//  RepositoryOperationTests.swift
//
//
//  Created by İbrahim Çetin on 18.06.2024.
//

import Foundation
import SwiftGitX
import Testing

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
