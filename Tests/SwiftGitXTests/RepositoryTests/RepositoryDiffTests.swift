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
        let file1 = try repository.mockFile()
        try repository.mockCommit(file: file1)

        // Update the file content
        try Data("The working tree content!\n".utf8).write(to: file1)

        // Get the diff between HEAD and the working tree
        let diff = try repository.diff()

        // Check if the diff count is correct
        #expect(diff.patches[0].hunks.count == 1)

        let hunk = diff.patches[0].hunks[0]

        // Check the hunk lines
        #expect(hunk.lines.count == 2)
        #expect(hunk.lines[0].type == .deletion)
        #expect(hunk.lines[0].content == "File 1 content\n")

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
        let file = try repository.mockFile(content: "The commit content!\n")

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
            file: repository.mockFile(name: "README.md", content: "Merhaba, Dünya!")
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
}

// MARK: - Helper Functions

/// This method creates two commits in the repository and returns them.
private func mockCommits(repository: Repository) throws -> (initialCommit: Commit, secondCommit: Commit) {
    let file = try repository.mockFile(name: "README.md", content: "Hello, SwiftGitX!\n")

    // Commit the changes
    let initialCommit = try repository.mockCommit(message: "Initial commit", file: file)

    // Modify the file
    try Data("Hello, World!\n".utf8).write(to: file)

    // Commit the changes
    let secondCommit = try repository.mockCommit(message: "Second commit", file: file)

    return (initialCommit, secondCommit)
}
