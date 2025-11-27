import Foundation
import SwiftGitX
import Testing

@Suite("Repository - Revert", .tags(.repository, .operation, .revert))
final class RepositoryRevertTests: SwiftGitXTest {
    @Test("Revert commit restores file content and stages changes")
    func revertRestoresContent() async throws {
        let repository = mockRepository()

        // Create initial commit with a file
        let file1 = try repository.mockFile()
        try repository.mockCommit(file: file1)

        // Modify file and commit the change we plan to revert
        try Data("Modified content".utf8).write(to: file1)
        try repository.add(file: file1)
        let commitToRevert = try repository.commit(message: "Modify file")

        // Revert the commit
        try repository.revert(commitToRevert)

        // File content should match the original commit
        #expect(try String(contentsOf: file1) == "File 1 content\n")

        // Changes should be staged but not committed
        #expect(try repository.status(file: file1) == [.indexModified])

        // HEAD should point to the commit we reverted to. Because,
        // git revert modifies the working tree/index but does not automatically create a new commit.
        #expect(commitToRevert.id == (try repository.HEAD.target.id))
    }

    @Test("Revert commit that added a file stages deletion")
    func revertAddedFile() async throws {
        let repository = mockRepository()
        try repository.mockCommit()

        // Create and commit a new file
        let file2 = try repository.mockFile()
        try repository.add(file: file2)
        let commitToRevert = try repository.commit(message: "Add file2")

        try repository.revert(commitToRevert)

        // File should be removed from working tree and staged as deletion
        #expect(FileManager.default.fileExists(atPath: file2.path) == false)
        #expect(try repository.status(file: file2) == [.indexDeleted])
    }

    @Test("Revert and then commit creates a new revert commit")
    func revertThenCommit() async throws {
        let repository = mockRepository()

        // Setup: initial commit -> change commit
        let file = try repository.mockFile()
        let initialCommit = try repository.mockCommit(file: file)

        try Data("Changed".utf8).write(to: file)
        try repository.add(file: file)
        let changeCommit = try repository.commit(message: "Change file")

        // Revert change and create revert commit
        try repository.revert(changeCommit)
        let revertCommit = try repository.commit(message: "Revert \"\(changeCommit.summary)\"")

        // Verify revert commit message
        #expect(revertCommit.message == "Revert \"Change file\"")

        // Revert commit should have change commit as parent
        let parents = try revertCommit.parents
        #expect(parents.count == 1)
        #expect(parents.first == changeCommit)

        // File content should match initial commit
        #expect(try String(contentsOf: file) == "File 1 content\n")

        // Verify commit order: revert -> change -> initial
        let log = Array(try repository.log())
        #expect(log.count == 3)
        #expect(log[0] == revertCommit)
        #expect(log[1] == changeCommit)
        #expect(log[2] == initialCommit)
    }

    @Test("Revert commit with multiple file changes restores all files")
    func revertMultipleFiles() async throws {
        let repository = mockRepository()

        // Create initial commit with two files
        let file1 = try repository.mockFile()
        let file2 = try repository.mockFile()
        try repository.add(files: [file1, file2])
        try repository.commit(message: "Initial commit")

        // Modify both files and commit
        try Data("File 1 modified".utf8).write(to: file1)
        try Data("File 2 modified".utf8).write(to: file2)
        try repository.add(files: [file1, file2])
        let commitToRevert = try repository.commit(message: "Modify both files")

        try repository.revert(commitToRevert)

        // Both files should be restored and staged
        #expect(try String(contentsOf: file1) == "File 1 content\n")
        #expect(try String(contentsOf: file2) == "File 2 content\n")
        #expect(try repository.status(file: file1) == [.indexModified])
        #expect(try repository.status(file: file2) == [.indexModified])
    }
}

@Suite("Repository - Revert Errors", .tags(.repository, .operation, .revert, .error))
final class RepositoryRevertErrorTests: SwiftGitXTest {
    @Test("Revert fails when working tree has conflicting changes")
    func revertConflictingWorkingTreeThrows() async throws {
        let repository = mockRepository()

        // Create initial commit with a file
        let file = try repository.mockFile()
        try repository.mockCommit(file: file)

        // Commit change we plan to revert
        try Data("Committed change".utf8).write(to: file)
        try repository.add(file: file)
        let commitToRevert = try repository.commit(message: "Change file")

        // Introduce conflicting working tree change
        try Data("Conflicting working tree change".utf8).write(to: file)

        let error = #expect(throws: SwiftGitXError.self) {
            try repository.revert(commitToRevert)
        }

        #expect(error?.code.isConflict == true)
    }
}
