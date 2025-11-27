import Foundation
import SwiftGitX
import Testing

@Suite("Repository - Status", .tags(.repository, .operation, .status))
final class RepositoryStatusTests: SwiftGitXTest {
    @Test("Repository status untracked")
    func repositoryStatusUntracked() async throws {
        let repository = mockRepository()

        // Create a new file in the repository
        _ = try repository.mockFile()

        // Get the status of the repository
        let status = try repository.status()

        // Check the status of the repository
        #expect(status.count == 1)

        // Get the status entry
        let statusEntry = try #require(status.first)

        // Check the status entry properties
        #expect(statusEntry.status == [.workingTreeNew])
        #expect(statusEntry.index == nil)  // There is no index changes

        // Get working tree changes
        let workingTreeChanges = try #require(statusEntry.workingTree)

        // Check the status entry diff delta properties
        #expect(workingTreeChanges.type == .untracked)

        #expect(workingTreeChanges.newFile.path == "file-1.txt")
        #expect(workingTreeChanges.oldFile.path == "file-1.txt")

        #expect(workingTreeChanges.newFile.size == "File 1 content\n".count)
        #expect(workingTreeChanges.oldFile.size == 0)
    }

    @Test("Repository status added")
    func repositoryStatusAdded() async throws {
        let repository = mockRepository()

        // Create a new file in the repository
        let file = try repository.mockFile()

        // Add the file
        try repository.add(file: file)

        // Get the status of the repository
        let status = try repository.status()

        // Check the status of the repository
        #expect(status.count == 1)

        // Get the status entry
        let statusEntry = try #require(status.first)

        // Check the status entry properties
        #expect(statusEntry.status == [.indexNew])
        #expect(statusEntry.workingTree == nil)  // There is no working tree changes
        let statusEntryDiffDelta = try #require(statusEntry.index)

        // Check the status entry diff delta properties
        #expect(statusEntryDiffDelta.type == .added)

        #expect(statusEntryDiffDelta.newFile.path == "file-1.txt")
        #expect(statusEntryDiffDelta.oldFile.path == "file-1.txt")

        #expect(statusEntryDiffDelta.newFile.size == "File 1 content\n".count)
        #expect(statusEntryDiffDelta.oldFile.size == 0)

        // Get the blob of the new file
        let blob: Blob = try repository.show(id: statusEntryDiffDelta.newFile.id)
        let blobText = try #require(String(data: blob.content, encoding: .utf8))
        #expect(blobText == "File 1 content\n")
    }

    @Test("Repository status file new and modified")
    func repositoryStatusFileNewAndModified() async throws {
        let repository = mockRepository()

        // Create a new file in the repository
        let file = try repository.mockFile()

        // Add the file
        try repository.add(file: file)

        // Modify the file
        try Data("Merhaba, Dünya!".utf8).write(to: file)

        // Get the status of the repository
        let status: [StatusEntry.Status] = try repository.status(file: file)

        // Check the status of the repository
        #expect(status.count == 2)

        // Check the status entry properties
        #expect(status == [.indexNew, .workingTreeModified])
    }
}
