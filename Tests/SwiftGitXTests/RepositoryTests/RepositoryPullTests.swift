import Foundation
import SwiftGitX
import Testing

@Suite("Repository - Pull", .tags(.repository, .operation, .pull))
final class RepositoryPullTests: SwiftGitXTest {
    @Test("Pull from remote repository - fast forward")
    func pullFastForward() async throws {
        let remoteRepository = mockRepository(suffix: "--remote")
        try remoteRepository.mockCommit(message: "Initial commit")

        let localDirectory = mockDirectory(suffix: "--local")
        let localRepository = try await Repository.clone(from: remoteRepository.workingDirectory, to: localDirectory)

        // Add another commit to the remote repository
        try remoteRepository.mockCommit(message: "Remote commit")

        // Get initial local HEAD
        let initialLocalHead = try localRepository.HEAD.target.id

        // Pull the changes
        try await localRepository.pull()

        // Verify local HEAD has been updated
        let finalLocalHead = try localRepository.HEAD.target.id
        let remoteHead = try remoteRepository.HEAD.target.id

        #expect(finalLocalHead == remoteHead)
        #expect(finalLocalHead != initialLocalHead)
    }

    @Test("Pull when already up to date")
    func pullUpToDate() async throws {
        let remoteRepository = mockRepository(suffix: "--remote")
        try remoteRepository.mockCommit(message: "Initial commit")

        let localDirectory = mockDirectory(suffix: "--local")
        let localRepository = try await Repository.clone(from: remoteRepository.workingDirectory, to: localDirectory)

        // Get initial local HEAD
        let initialLocalHead = try localRepository.HEAD.target.id

        // Pull when already up to date
        try await localRepository.pull()

        // Verify local HEAD is unchanged
        let finalLocalHead = try localRepository.HEAD.target.id
        #expect(finalLocalHead == initialLocalHead)
    }

    @Test("Pull with normal merge")
    func pullNormalMerge() async throws {
        let remoteRepository = mockRepository(suffix: "--remote")
        try remoteRepository.mockCommit(message: "Initial commit")

        let localDirectory = mockDirectory(suffix: "--local")
        let localRepository = try await Repository.clone(from: remoteRepository.workingDirectory, to: localDirectory)

        // Add a commit to the remote repository
        try remoteRepository.mockCommit(message: "Remote commit")

        // Add a different commit to the local repository (creates divergence)
        try localRepository.mockCommit(message: "Local commit")

        // Pull the changes (should create merge commit)
        try await localRepository.pull()

        // Verify that we now have a merge commit (commit with 2 parents)
        let headCommit = try localRepository.HEAD.target as! Commit
        let parents = try headCommit.parents
        #expect(parents.count == 2)
    }

    @Test("Pull fails without upstream branch")
    func pullWithoutUpstream() async throws {
        let repository = mockRepository()
        try repository.mockCommit()

        // Try to pull without upstream configured
        await #expect(throws: SwiftGitXError.self) {
            try await repository.pull()
        }
    }

    @Test("Pull multiple commits")
    func pullMultipleCommits() async throws {
        let remoteRepository = mockRepository(suffix: "--remote")
        try remoteRepository.mockCommit(message: "Initial commit")

        let localDirectory = mockDirectory(suffix: "--local")
        let localRepository = try await Repository.clone(from: remoteRepository.workingDirectory, to: localDirectory)

        // Add multiple commits to remote
        try remoteRepository.mockCommit(message: "Second commit")
        try remoteRepository.mockCommit(message: "Third commit")
        try remoteRepository.mockCommit(message: "Fourth commit")

        // Pull all changes
        try await localRepository.pull()

        // Verify local HEAD matches remote HEAD
        let localHead = try localRepository.HEAD.target.id
        let remoteHead = try remoteRepository.HEAD.target.id
        #expect(localHead == remoteHead)

        // Verify commit count matches
        let localCommitCount = try localRepository.log().reduce(0) { count, _ in count + 1 }
        let remoteCommitCount = try remoteRepository.log().reduce(0) { count, _ in count + 1 }
        #expect(localCommitCount == remoteCommitCount)
    }

    // MARK: - Pull Options

    @Test("Pull with fastForwardOnly option - success")
    func pullFastForwardOnly() async throws {
        let remoteRepository = mockRepository(suffix: "--remote")
        try remoteRepository.mockCommit(message: "Initial commit")

        let localDirectory = mockDirectory(suffix: "--local")
        let localRepository = try await Repository.clone(from: remoteRepository.workingDirectory, to: localDirectory)

        try remoteRepository.mockCommit(message: "Remote commit")

        try await localRepository.pull(option: .fastForwardOnly)

        let localHead = try localRepository.HEAD.target.id
        let remoteHead = try remoteRepository.HEAD.target.id
        #expect(localHead == remoteHead)
    }

    @Test("Pull with fastForwardOnly option - fails when merge required")
    func pullFastForwardOnlyFails() async throws {
        let remoteRepository = mockRepository(suffix: "--remote")
        try remoteRepository.mockCommit(message: "Initial commit")

        let localDirectory = mockDirectory(suffix: "--local")
        let localRepository = try await Repository.clone(from: remoteRepository.workingDirectory, to: localDirectory)

        try remoteRepository.mockCommit(message: "Remote commit")
        try localRepository.mockCommit(message: "Local commit")

        await #expect(throws: SwiftGitXError.self) {
            try await localRepository.pull(option: .fastForwardOnly)
        }
    }

    @Test("Pull with noFastForward option - creates merge commit")
    func pullNoFastForward() async throws {
        let remoteRepository = mockRepository(suffix: "--remote")
        try remoteRepository.mockCommit(message: "Initial commit")

        let localDirectory = mockDirectory(suffix: "--local")
        let localRepository = try await Repository.clone(from: remoteRepository.workingDirectory, to: localDirectory)

        try remoteRepository.mockCommit(message: "Remote commit")

        try await localRepository.pull(option: .noFastForward)

        let headCommit = try localRepository.HEAD.target as! Commit
        let parents = try headCommit.parents
        #expect(parents.count == 2)
    }

    @Test("Pull with rebase option - fast forward case")
    func pullRebase() async throws {
        let remoteRepository = mockRepository(suffix: "--remote")
        try remoteRepository.mockCommit(message: "Initial commit")

        let localDirectory = mockDirectory(suffix: "--local")
        let localRepository = try await Repository.clone(from: remoteRepository.workingDirectory, to: localDirectory)

        try remoteRepository.mockCommit(message: "Remote commit")

        try await localRepository.pull(option: .rebase)

        // After rebase with no local commits, should match remote
        let localHead = try localRepository.HEAD.target.id
        let remoteHead = try remoteRepository.HEAD.target.id
        #expect(localHead == remoteHead)
    }
}
