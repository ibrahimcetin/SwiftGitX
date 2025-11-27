import Foundation
import SwiftGitX
import Testing

@Suite("Repository - Patch", .tags(.repository, .operation, .patch))
final class RepositoryPatchTests: SwiftGitXTest {
    @Test("Patch create from blobs")
    func patchCreateFromBlobs() async throws {
        let repository = mockRepository()

        // Create a commit
        let file = try repository.mockFile(content: "The old data!\n")
        try repository.mockCommit(file: file)

        // Update the file content and add the file
        try Data("The new data!\n".utf8).write(to: file)
        // * The working tree file does not have a blob object, so we need to add the file at least.
        try repository.add(file: file)

        // Get the status of the file
        let status = try #require(repository.status().first)
        #expect(status.status == [.indexModified])

        // Lookup blobs
        let oldBlobID = try #require(status.index?.oldFile.id)
        let oldBlob: Blob = try repository.show(id: oldBlobID)

        let newBlobID = try #require(status.index?.newFile.id)
        let newBlob: Blob = try repository.show(id: newBlobID)

        // Create patch from status blobs
        let patch = try repository.patch(from: oldBlob, to: newBlob)

        // Check the patch properties
        #expect(patch.hunks.count == 1)
        #expect(patch.hunks[0].lines[0].content == "The old data!\n")
        #expect(patch.hunks[0].lines[1].content == "The new data!\n")
    }

    @Test("Patch create from blob to file")
    func patchCreateFromBlobToFile() async throws {
        let repository = mockRepository()

        // Create a commit
        let file = try repository.mockFile(content: "The old data!\n")
        try repository.mockCommit(file: file)

        // Update the file content and add the file
        try Data("The new data!\n".utf8).write(to: file)

        // Get the status of the file
        let status = try #require(repository.status().first)
        #expect(status.status == [.workingTreeModified])

        // Lookup blobs
        let oldBlobID = try #require(status.workingTree?.oldFile.id)
        let oldBlob: Blob = try repository.show(id: oldBlobID)

        // Create patch from status blobs
        let patch = try repository.patch(from: oldBlob, to: file)

        // Check the patch properties
        #expect(patch.hunks.count == 1)
        #expect(patch.hunks[0].lines[0].content == "The old data!\n")
        #expect(patch.hunks[0].lines[1].content == "The new data!\n")
    }

    @Test("Patch create from delta modified")
    func patchCreateFromDeltaModified() async throws {
        let repository = mockRepository()

        // Create a commit
        let file = try repository.mockFile(content: "The old data!\n")
        try repository.mockCommit(file: file)

        // Update the file content and add the file
        try Data("The new data!\n".utf8).write(to: file)

        // Get the status of the file
        let status: StatusEntry = try #require(repository.status().first)
        #expect(status.status == [.workingTreeModified])
        let workingTreeDelta = try #require(status.workingTree)

        // Create patch from workingTree delta
        let workingTreePatch = try #require((try repository.patch(from: workingTreeDelta)))

        // Check the patch properties
        #expect(workingTreePatch.hunks.count == 1)
        #expect(workingTreePatch.hunks[0].lines[0].content == "The old data!\n")
        #expect(workingTreePatch.hunks[0].lines[1].content == "The new data!\n")
    }

    @Test("Patch create from delta indexed")
    func patchCreateFromDeltaIndexed() async throws {
        let repository = mockRepository()

        // Create a commit
        let file = try repository.mockFile(content: "The old data!\n")
        try repository.mockCommit(file: file)

        // Update the file content and add the file
        try Data("The new data!\n".utf8).write(to: file)
        try repository.add(file: file)

        // Get the status of the file
        let status: StatusEntry = try #require(repository.status().first)
        #expect(status.status == [.indexModified])
        let indexDelta = try #require(status.index)

        // Create patch from workingTree delta
        let indexPatch = try #require((try repository.patch(from: indexDelta)))

        // Check the patch properties
        #expect(indexPatch.hunks.count == 1)
        #expect(indexPatch.hunks[0].lines[0].content == "The old data!\n")
        #expect(indexPatch.hunks[0].lines[1].content == "The new data!\n")
    }

    @Test("Patch create from delta untracked")
    func patchCreateFromDeltaUntracked() async throws {
        let repository = mockRepository()

        // Create a new file in the repository
        _ = try repository.mockFile(content: "Hello, World!\n")

        // Get the status of the file
        let status: StatusEntry = try #require(repository.status().first)
        #expect(status.status == [.workingTreeNew])  // The file is untracked
        let workingTreeDelta = try #require(status.workingTree)

        // Create patch from workingTree delta
        let workingTreePatch = try #require((try repository.patch(from: workingTreeDelta)))

        // Check the patch properties
        #expect(workingTreePatch.hunks.count == 1)
        #expect(workingTreePatch.hunks[0].lines[0].content == "Hello, World!\n")
    }

    @Test("Patch create from empty blobs")
    func patchCreateFromEmptyBlobs() async throws {
        let repository = mockRepository()

        // Create patch from empty blobs
        let patch = try repository.patch(from: nil, to: nil)

        // Check the patch properties
        #expect(patch.hunks.count == 0)
    }
}
