import Foundation
import SwiftGitX
import Testing

@Suite("Repository - Restore", .tags(.repository, .operation, .restore))
final class RepositoryRestoreTests: SwiftGitXTest {
    @Test("Restore working tree file")
    func restoreWorkingTree() async throws {
        let repository = mockRepository()

        // Create and commit a file
        let file1 = try repository.mockFile()
        try repository.mockCommit(file: file1)

        // Modify the file (working tree change)
        try Data("Restore me!".utf8).write(to: file1)

        // Create and stage another file (should not be restored)
        let file2 = try repository.mockFile()
        try repository.add(file: file2)

        // Restore
        try repository.restore(files: [file1, file2])

        // Verify file content is restored
        let restoredContent = try String(contentsOf: file1)
        #expect(restoredContent == "File 1 content\n")

        // Verify file2 is still staged
        #expect(FileManager.default.fileExists(atPath: file2.path))
        #expect(try repository.status(file: file2) == [.indexNew])
    }

    @Test("Restore staged file")
    func restoreStaged() async throws {
        let repository = mockRepository()

        // Create and commit a file
        let workingTreeFile = try repository.mockFile(name: "WorkingTree.md", content: "Hello, World!")
        try repository.mockCommit(file: workingTreeFile)

        // Modify the file (should not be restored)
        try Data("Should not be restored!".utf8).write(to: workingTreeFile)

        // Create and stage another file
        let stagedFile = try repository.mockFile(name: "Stage.md", content: "Stage me!")
        try repository.add(file: stagedFile)

        // Restore staged only
        try repository.restore(.staged, paths: ["WorkingTree.md", "Stage.md"])

        // Staged file should be unstaged
        let stagedFileStatus = try repository.status(file: stagedFile)
        #expect(stagedFileStatus == [.workingTreeNew])
        #expect(try String(contentsOf: stagedFile) == "Stage me!")

        // Working tree file should still be modified
        let workingTreeFileStatus = try repository.status(file: workingTreeFile)
        #expect(workingTreeFileStatus == [.workingTreeModified])
        #expect(try String(contentsOf: workingTreeFile) == "Should not be restored!")
    }

    @Test("Restore both working tree and staged")
    func restoreWorkingTreeAndStaged() async throws {
        let repository = mockRepository()

        let file = try repository.mockFile()
        try repository.mockCommit(file: file)

        // Modify file from mockCommit and stage it
        try Data("Restore stage area!".utf8).write(to: file)
        try repository.add(file: file)

        // Modify again (working tree change)
        try Data("Restore working tree!".utf8).write(to: file)

        // Restore both
        try repository.restore([.workingTree, .staged], files: [file])

        // File should have no changes
        let status = try repository.status(file: file)
        #expect(status.isEmpty)
        #expect(try String(contentsOf: file) == "File 1 content\n")
    }

    @Test("Restore deletes untracked staged file")
    func restoreDeletesUntrackedStagedFile() async throws {
        let repository = mockRepository()
        try repository.mockCommit()

        // Create and stage a new file
        let fileToDelete = try repository.mockFile(name: "DeleteMe.md", content: "Delete me from stage area!")
        try repository.add(file: fileToDelete)

        // Modify it
        try Data("Delete me from working tree!".utf8).write(to: fileToDelete)

        // Restore both working tree and staged
        try repository.restore([.workingTree, .staged], files: [fileToDelete])

        // File should be deleted
        #expect(FileManager.default.fileExists(atPath: fileToDelete.path) == false)
    }
}
