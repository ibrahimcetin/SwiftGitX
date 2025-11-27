import Foundation
import SwiftGitX
import Testing

// MARK: - Basic Commit Operations

@Suite("Repository - Commit", .tags(.repository, .operation, .commit))
final class RepositoryCommitTests: SwiftGitXTest {
    @Test("Commit staged changes")
    func commitStagedChanges() async throws {
        let repository = mockRepository()

        // Create and stage a file
        let file = try repository.mockFile()
        try repository.add(file: file)

        // Commit
        let commit = try repository.commit(message: "Initial commit")

        // Verify HEAD points to commit
        let headCommit = try #require(repository.HEAD.target as? Commit)
        #expect(commit == headCommit)
    }

    @Test("Initial commit has no parents")
    func initialCommitNoParents() async throws {
        let repository = mockRepository()

        // Create initial commit
        try repository.add(file: repository.mockFile())
        let initialCommit = try repository.commit(message: "Initial commit")

        #expect(initialCommit.id == (try repository.HEAD.target.id))
        #expect(try initialCommit.parents.isEmpty)
    }

    @Test("Commit has parent")
    func commitHasParent() async throws {
        let repository = mockRepository()

        // Create initial commit
        let initialCommit = try repository.mockCommit()

        // Create second commit
        try repository.add(file: repository.mockFile())
        let secondCommit = try repository.commit(message: "Second commit")

        // Verify parent
        let parents = try secondCommit.parents
        #expect(parents.count == 1)
        #expect(parents.first == initialCommit)
    }

    @Test("Commit chain has correct parents")
    func commitChain() async throws {
        let repository = mockRepository()

        // Create chain of 5 commits
        let commits = try (0..<5).map { _ in try repository.mockCommit() }

        // Verify each commit's parent (except first)
        for i in 1..<commits.count {
            let parents = try commits[i].parents
            #expect(parents.count == 1)
            #expect(parents.first == commits[i - 1])
        }

        // First commit has no parents
        #expect(try commits[0].parents.isEmpty)
    }
}

// MARK: - Commit Message

@Suite("Repository - Commit Message", .tags(.repository, .operation, .commit))
final class RepositoryCommitMessageTests: SwiftGitXTest {
    @Test("Single line message")
    func singleLineMessage() async throws {
        let repository = mockRepository()

        try repository.add(file: repository.mockFile())
        let commit = try repository.commit(message: "Simple message")

        #expect(commit.message == "Simple message")
        #expect(commit.summary == "Simple message")
        #expect(commit.body == nil)
    }

    @Test("Multiline message with summary and body")
    func multilineMessage() async throws {
        let repository = mockRepository()

        let message = """
            Add new feature

            This commit adds a new feature that does something amazing.
            It includes multiple lines of description.
            """

        try repository.add(file: repository.mockFile())
        let commit = try repository.commit(message: message)

        #expect(commit.summary == "Add new feature")
        #expect(commit.body != nil)
        #expect(commit.body?.contains("something amazing") == true)
    }

    @Test("Message with empty body")
    func messageWithEmptyBody() async throws {
        let repository = mockRepository()

        try repository.add(file: repository.mockFile())
        let commit = try repository.commit(message: "Just a summary\n\n")

        #expect(commit.summary == "Just a summary")
        #expect(commit.body == nil)
    }
}

// MARK: - Commit Metadata

@Suite("Repository - Commit Metadata", .tags(.repository, .operation, .commit))
final class RepositoryCommitMetadataTests: SwiftGitXTest {
    @Test("Commit has author signature")
    func commitHasAuthor() async throws {
        let repository = mockRepository()

        try repository.add(file: repository.mockFile())
        let commit = try repository.commit(message: "Test commit")

        // Author should have name and email from git config
        #expect(commit.author.name.isEmpty == false)
        #expect(commit.author.email.isEmpty == false)
    }

    @Test("Commit has committer signature")
    func commitHasCommitter() async throws {
        let repository = mockRepository()

        try repository.add(file: repository.mockFile())
        let commit = try repository.commit(message: "Test commit")

        // Committer should have name and email from git config
        #expect(commit.committer.name.isEmpty == false)
        #expect(commit.committer.email.isEmpty == false)
    }

    @Test("Commit date is recent")
    func commitDateIsRecent() async throws {
        let repository = mockRepository()

        let before = Date.now
        try repository.add(file: repository.mockFile())
        let commit = try repository.commit(message: "Test commit")
        let after = Date.now

        // Commit date should be between before and after (with 1 second tolerance)
        #expect(commit.date.timeIntervalSince1970 >= before.timeIntervalSince1970 - 1)
        #expect(commit.date.timeIntervalSince1970 <= after.timeIntervalSince1970 + 1)
    }

    @Test("Commit has correct type")
    func commitHasCorrectType() async throws {
        let repository = mockRepository()

        try repository.add(file: repository.mockFile())
        let commit = try repository.commit(message: "Test commit")

        #expect(commit.type == .commit)
    }
}

// MARK: - Commit Tree

@Suite("Repository - Commit Tree", .tags(.repository, .operation, .commit))
final class RepositoryCommitTreeTests: SwiftGitXTest {
    @Test("Commit tree contains committed file")
    func commitTreeContainsFile() async throws {
        let repository = mockRepository()

        // Create and commit a file
        try repository.add(file: repository.mockFile())
        let commit = try repository.commit(message: "Add README")

        // Get tree and verify file exists
        let tree = try commit.tree
        let entry = tree.entries.first { $0.name == "file-1.txt" }

        #expect(entry != nil)
        #expect(entry?.type == .blob)
    }

    @Test("Commit tree reflects all staged files")
    func commitTreeReflectsAllFiles() async throws {
        let repository = mockRepository()

        // Create multiple files
        let files = try (0..<3).map { _ in try repository.mockFile() }

        try repository.add(files: files)
        let commit = try repository.commit(message: "Add files")

        // Verify all files are in tree
        let tree = try commit.tree
        let fileNames = tree.entries.map(\.name).sorted()

        #expect(fileNames == files.map(\.lastPathComponent))
    }
}

// MARK: - Commit Options

@Suite("Repository - Commit Options", .tags(.repository, .operation, .commit))
final class RepositoryCommitOptionsTests: SwiftGitXTest {
    @Test("Default options require staged changes")
    func defaultOptionsRequireChanges() async throws {
        let repository = mockRepository()
        try repository.mockCommit()

        // Default options should fail with no changes
        #expect(throws: SwiftGitXError.self) {
            try repository.commit(message: "No changes", options: .default)
        }
    }

    @Test("allowEmpty option permits empty commit")
    func allowEmptyOption() async throws {
        let repository = mockRepository()
        try repository.mockCommit()

        // allowEmpty should succeed
        let emptyCommit = try repository.commit(message: "Empty commit", options: .allowEmpty)

        #expect(emptyCommit.message == "Empty commit")
    }

    @Test("Custom CommitOptions with allowEmpty")
    func customCommitOptions() async throws {
        let repository = mockRepository()
        try repository.mockCommit()

        // Create custom options
        let options = CommitOptions(allowEmpty: true)
        let commit = try repository.commit(message: "Custom options", options: options)

        #expect(commit.message == "Custom options")
    }
}

// MARK: - Commit Error Cases

@Suite("Repository - Commit Errors", .tags(.repository, .operation, .commit, .error))
final class RepositoryCommitErrorTests: SwiftGitXTest {
    @Test("Commit with no staged changes throws error")
    func noStagedChangesThrows() async throws {
        let repository = mockRepository()
        try repository.mockCommit()

        let error = #expect(throws: SwiftGitXError.self) {
            try repository.commit(message: "No changes")
        }

        #expect(error?.code == .unchanged)
        #expect(error?.category == .repository)
        #expect(error?.message == "no changes are staged for commit")
    }

    @Test("Commit on empty repository with no staged files throws")
    func emptyRepositoryNoStagedThrows() async throws {
        let repository = mockRepository()

        // No files staged, no initial commit
        #expect(throws: SwiftGitXError.self) {
            try repository.commit(message: "Should fail")
        }
    }
}
