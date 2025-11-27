import Foundation
import SwiftGitX
import Testing

// MARK: - Diff HEAD to Working Tree

@Suite("Repository - Diff HEAD to Working Tree", .tags(.repository, .operation, .diff))
final class RepositoryDiffHEADToWorkingTreeTests: SwiftGitXTest {
    @Test("Diff HEAD to working tree")
    func diffHEADToWorkingTree() async throws {
        let repository = mockRepository()

        // Create a commit
        let file = try repository.mockFile(named: "README.md", content: "The commit content!\n")
        try repository.mockCommit(file: file)

        // Update the file content
        try Data("The working tree content!\n".utf8).write(to: file)

        // Get the diff between HEAD and the working tree
        let diff = try repository.diff()

        // Check if the diff count is correct
        #expect(diff.patches[0].hunks.count == 1)

        let hunk = diff.patches[0].hunks[0]

        // Check the hunk lines
        #expect(hunk.lines.count == 2)
        #expect(hunk.lines[0].type == .deletion)
        #expect(hunk.lines[0].content == "The commit content!\n")

        #expect(hunk.lines[1].type == .addition)
        #expect(hunk.lines[1].content == "The working tree content!\n")
    }

    @Test("Diff HEAD to working tree with staged changes")
    func diffHEADToWorkingTreeStaged() async throws {
        let repository = mockRepository()

        // Create a base state for the test
        try createBaseStateForDiffHEAD(repository)

        // Get the diff between HEAD and the working tree
        let diff = try repository.diff()

        // Check if the diff count is correct
        #expect(diff.patches[0].hunks.count == 1)

        let hunk = diff.patches[0].hunks[0]

        // Check the hunk lines
        #expect(hunk.lines.count == 3)
        #expect(hunk.lines[0].type == .deletion)
        #expect(hunk.lines[0].content == "The index content!\n")

        #expect(hunk.lines[1].content == "\n")

        #expect(hunk.lines[2].type == .addition)
        #expect(hunk.lines[2].content == "The working tree content!\n")
    }

    @Test("Diff HEAD to index")
    func diffHEADToIndex() async throws {
        let repository = mockRepository()

        // Create a base state for the test
        try createBaseStateForDiffHEAD(repository)

        // Get the diff between HEAD and the index
        let diff = try repository.diff(to: .index)

        // Check if the diff count is correct
        #expect(diff.patches[0].hunks.count == 1)

        let hunk = diff.patches[0].hunks[0]

        // Check the hunk lines
        #expect(hunk.lines.count == 2)
        #expect(hunk.lines[0].type == .deletion)
        #expect(hunk.lines[0].content == "The commit content!\n")

        #expect(hunk.lines[1].type == .addition)
        #expect(hunk.lines[1].content == "The index content!\n")
    }

    @Test("Diff HEAD to working tree with index")
    func diffHEADToWorkingTreeWithIndex() async throws {
        let repository = mockRepository()

        // Create a base state for the test
        try createBaseStateForDiffHEAD(repository)

        // Get the diff between HEAD and the working tree with index
        let diff = try repository.diff(to: [.index, .workingTree])

        // Check if the diff count is correct
        #expect(diff.patches[0].hunks.count == 1)

        let hunk = diff.patches[0].hunks[0]

        // Check the hunk lines
        #expect(hunk.lines.count == 3)
        #expect(hunk.lines[0].type == .deletion)
        #expect(hunk.lines[0].content == "The commit content!\n")

        #expect(hunk.lines[1].content == "\n")

        #expect(hunk.lines[2].type == .addition)
        #expect(hunk.lines[2].content == "The working tree content!\n")
    }

    /// This func creates base state for diff HEAD tests. It creates a commit, a staged change and a working tree change.
    private func createBaseStateForDiffHEAD(_ repository: Repository) throws {
        // Create a file
        let file = try repository.mockFile(named: "README.md", content: "The commit content!\n")

        // Create a commit
        try repository.mockCommit(file: file)

        // Update the file content and add the file
        try Data("The index content!\n".utf8).write(to: file)
        try repository.add(file: file)

        // Update the file content
        try Data("\nThe working tree content!\n".utf8).write(to: file)
    }
}

// MARK: - Diff Between Objects

@Suite("Repository - Diff Between Objects", .tags(.repository, .operation, .diff))
final class RepositoryDiffBetweenObjectsTests: SwiftGitXTest {
    @Test("Diff between commit and commit")
    func diffBetweenCommitAndCommit() async throws {
        let repository = mockRepository()

        // Create commits
        let (initialCommit, secondCommit) = try mockCommits(repository: repository)

        // Get the diff between the two commits
        let diff = try repository.diff(from: initialCommit, to: secondCommit)

        // Check if the diff count is correct
        #expect(diff.changes.count == 1)

        // Get the change
        let change = try #require(diff.changes.first)

        // Check the change
        #expect(change.oldFile.path == "README.md")
        #expect(change.newFile.path == "README.md")
        #expect(change.type == .modified)

        // Get the blob of the new file
        let newBlob: Blob = try repository.show(id: change.newFile.id)

        // Check the blob content
        let newContent = try #require(String(data: newBlob.content, encoding: .utf8))
        #expect(newContent == "Hello, World!\n")
    }

    @Test("Diff between tree and tree")
    func diffBetweenTreeAndTree() async throws {
        let repository = mockRepository()

        // Create commits
        let (initialCommit, secondCommit) = try mockCommits(repository: repository)

        // Get the diff between the two commits
        let diff = try repository.diff(from: initialCommit.tree, to: secondCommit.tree)

        // Check if the diff count is correct
        #expect(diff.changes.count == 1)

        // Get the change
        let change = try #require(diff.changes.first)

        // Check the change
        #expect(change.oldFile.path == "README.md")
        #expect(change.newFile.path == "README.md")
        #expect(change.type == .modified)

        // Get the blob of the new file
        let newBlob: Blob = try repository.show(id: change.newFile.id)

        // Check the blob content
        let newContent = try #require(String(data: newBlob.content, encoding: .utf8))
        #expect(newContent == "Hello, World!\n")
    }

    @Test("Diff between tag and tag")
    func diffBetweenTagAndTag() async throws {
        let repository = mockRepository()

        // Create commits
        let (initialCommit, secondCommit) = try mockCommits(repository: repository)

        // Create a tag for the initial commit
        let initialTag = try repository.tag.create(named: "initial-tag", target: initialCommit)

        // Create a tag for the second commit
        let secondTag = try repository.tag.create(named: "second-tag", target: secondCommit)

        // Get the diff between the two commits
        let diff = try repository.diff(from: initialTag, to: secondTag)

        // Check if the diff count is correct
        #expect(diff.changes.count == 1)

        // Get the change
        let change = try #require(diff.changes.first)

        // Check the change
        #expect(change.oldFile.path == "README.md")
        #expect(change.newFile.path == "README.md")
        #expect(change.type == .modified)

        // Get the blob of the new file
        let newBlob: Blob = try repository.show(id: change.newFile.id)

        // Check the blob content
        let newContent = try #require(String(data: newBlob.content, encoding: .utf8))
        #expect(newContent == "Hello, World!\n")
    }

    /// This method creates two commits in the repository and returns them.
    private func mockCommits(repository: Repository) throws -> (initialCommit: Commit, secondCommit: Commit) {
        let file = try repository.mockFile(named: "README.md", content: "Hello, SwiftGitX!\n")

        // Commit the changes
        let initialCommit = try repository.mockCommit(message: "Initial commit", file: file)

        // Modify the file
        try Data("Hello, World!\n".utf8).write(to: file)

        // Commit the changes
        let secondCommit = try repository.mockCommit(message: "Second commit", file: file)

        return (initialCommit, secondCommit)
    }
}

// MARK: - Diff Commit

@Suite("Repository - Diff Commit", .tags(.repository, .operation, .diff))
final class RepositoryDiffCommitTests: SwiftGitXTest {
    @Test("Diff commit with parent")
    func diffCommitParent() async throws {
        let repository = mockRepository()

        // Create commits
        _ = try mockCommits(repository: repository)

        // Remove old content and write new content than commit
        let headCommit = try repository.mockCommit(
            message: "Third commit",
            file: repository.mockFile(named: "README.md", content: "Merhaba, Dünya!")
        )

        // Get the diff between the latest commit and its parent
        let diff = try repository.diff(commit: headCommit)

        // Check if the diff count is correct
        #expect(diff.changes.count == 1)

        // Get the change
        let change = try #require(diff.changes.first)

        // Check the change
        #expect(change.type == .modified)
        #expect(change.oldFile.path == "README.md")
        #expect(change.newFile.path == "README.md")

        // Get the blob of the new file
        let newBlob: Blob = try repository.show(id: change.newFile.id)
        let newText = try #require(String(data: newBlob.content, encoding: .utf8))

        // Get the blob of the old file
        let oldBlob: Blob = try repository.show(id: change.oldFile.id)
        let oldText = try #require(String(data: oldBlob.content, encoding: .utf8))

        // Check the blob content and size
        #expect(newText == "Merhaba, Dünya!")
        #expect(oldText == "Hello, World!\n")
    }

    @Test("Diff commit with no parent")
    func diffCommitNoParent() async throws {
        let repository = mockRepository()

        // Create a commit
        let commit = try repository.mockCommit()

        // Get the diff between the commit and its parent
        let diff = try repository.diff(commit: commit)

        // Check if the diff count is correct
        #expect(diff.changes.count == 0)
    }

    /// This method creates two commits in the repository and returns them.
    private func mockCommits(repository: Repository) throws -> (initialCommit: Commit, secondCommit: Commit) {
        let file = try repository.mockFile(named: "README.md", content: "Hello, SwiftGitX!\n")

        // Commit the changes
        let initialCommit = try repository.mockCommit(message: "Initial commit", file: file)

        // Modify the file
        try Data("Hello, World!\n".utf8).write(to: file)

        // Commit the changes
        let secondCommit = try repository.mockCommit(message: "Second commit", file: file)

        return (initialCommit, secondCommit)
    }
}

// MARK: - Repository Status

@Suite("Repository - Status", .tags(.repository, .operation, .diff))
final class RepositoryStatusTests: SwiftGitXTest {
    @Test("Repository status untracked")
    func repositoryStatusUntracked() async throws {
        let repository = mockRepository()

        // Create a new file in the repository
        _ = try repository.mockFile(named: "README.md", content: "Hello, World!")

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

        #expect(workingTreeChanges.newFile.path == "README.md")
        #expect(workingTreeChanges.oldFile.path == "README.md")

        #expect(workingTreeChanges.newFile.size == "Hello, World!".count)
        #expect(workingTreeChanges.oldFile.size == 0)
    }

    @Test("Repository status added")
    func repositoryStatusAdded() async throws {
        let repository = mockRepository()

        // Create a new file in the repository
        let file = try repository.mockFile(named: "README.md", content: "Hello, World!")

        // Add the file
        try repository.add(path: file.lastPathComponent)

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

        #expect(statusEntryDiffDelta.newFile.path == "README.md")
        #expect(statusEntryDiffDelta.oldFile.path == "README.md")

        #expect(statusEntryDiffDelta.newFile.size == "Hello, World!".count)
        #expect(statusEntryDiffDelta.oldFile.size == 0)

        // Get the blob of the new file
        let blob: Blob = try repository.show(id: statusEntryDiffDelta.newFile.id)
        let blobText = try #require(String(data: blob.content, encoding: .utf8))
        #expect(blobText == "Hello, World!")
    }

    @Test("Repository status file new and modified")
    func repositoryStatusFileNewAndModified() async throws {
        let repository = mockRepository()

        // Create a new file in the repository
        let file = try repository.mockFile(named: "README.md", content: "Hello, World!")

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

// MARK: - Diff Equality

@Suite("Repository - Diff Equality", .tags(.repository, .operation, .diff))
final class RepositoryDiffEqualityTests: SwiftGitXTest {
    @Test("Diff equality")
    func diffEquality() async throws {
        let repository = mockRepository()

        // Create mock commits
        let (initialCommit, secondCommit) = try mockCommits(repository: repository)

        // Get the diff between the two commits
        let diff = try repository.diff(from: initialCommit, to: secondCommit)

        // Open second repository at the same directory
        let sameRepository = try Repository.open(at: repository.workingDirectory)

        // Get the diff between the two commits
        let sameDiff = try sameRepository.diff(from: initialCommit, to: secondCommit)

        // Check the diff properties are equal between the two repositories
        #expect(sameDiff == diff)
    }

    /// This method creates two commits in the repository and returns them.
    private func mockCommits(repository: Repository) throws -> (initialCommit: Commit, secondCommit: Commit) {
        let file = try repository.mockFile(named: "README.md", content: "Hello, SwiftGitX!\n")

        // Commit the changes
        let initialCommit = try repository.mockCommit(message: "Initial commit", file: file)

        // Modify the file
        try Data("Hello, World!\n".utf8).write(to: file)

        // Commit the changes
        let secondCommit = try repository.mockCommit(message: "Second commit", file: file)

        return (initialCommit, secondCommit)
    }
}

// MARK: - Patch Creation

@Suite("Repository - Patch Creation", .tags(.repository, .operation, .diff))
final class RepositoryPatchCreationTests: SwiftGitXTest {
    @Test("Patch create from blobs")
    func patchCreateFromBlobs() async throws {
        let repository = mockRepository()

        // Create a commit
        let file = try repository.mockFile(named: "README.md", content: "The old data!\n")
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
        let file = try repository.mockFile(named: "README.md", content: "The old data!\n")
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
        let file = try repository.mockFile(named: "README.md", content: "The old data!\n")
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
        let file = try repository.mockFile(named: "README.md", content: "The old data!\n")
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
        _ = try repository.mockFile(named: "README.md", content: "Hello, World!\n")

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

    @Test("Patch create empty blobs")
    func patchCreateEmptyBlobs() async throws {
        let repository = mockRepository()

        // Create patch from empty blobs
        let patch = try repository.patch(from: nil, to: nil)

        // Check the patch properties
        #expect(patch.hunks.count == 0)
    }
}
