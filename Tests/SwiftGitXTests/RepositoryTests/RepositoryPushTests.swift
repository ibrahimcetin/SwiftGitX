import Foundation
import SwiftGitX
import Testing

@Suite("Repository - Push", .tags(.repository, .operation, .push))
final class RepositoryPushTests: SwiftGitXTest {
    @Test("Push to remote repository")
    func pushToRemote() async throws {
        // Create a mock repository at the temporary directory
        let source = URL(string: "https://github.com/ibrahimcetin/SwiftGitX.git")!
        let remoteDirectory = mockDirectory(suffix: "--remote")
        let remoteRepository = try await Repository.clone(from: source, to: remoteDirectory, options: .bare)

        // Clone the remote repository to the local repository
        let localDirectory = mockDirectory(suffix: "--local")
        let localRepository = try await Repository.clone(from: remoteDirectory, to: localDirectory)

        // Create a new commit in the local repository
        try localRepository.mockCommit(message: "Pushed commit", file: localRepository.mockFile(name: "PushedFile.md"))

        // Push the commit to the remote repository
        try await localRepository.push()

        // Check if the commit is pushed
        #expect(try localRepository.HEAD.target.id == remoteRepository.HEAD.target.id)
    }

    @Test("Push to empty remote and set upstream")
    func pushEmptyRemoteSetUpstream() async throws {
        // Create a mock repository at the temporary directory
        let remoteRepository = mockRepository(suffix: "--remote", isBare: true)

        // Create a mock repository at the temporary directory
        let localRepository = mockRepository(suffix: "--local")

        // Create a new commit in the local repository
        try localRepository.mockCommit(message: "Pushed commit", file: localRepository.mockFile(name: "PushedFile.md"))

        // Add remote repository to the local repository
        try localRepository.remote.add(named: "origin", at: remoteRepository.path)

        // Push the commit to the remote repository
        try await localRepository.push()

        // Check if the commit is pushed
        #expect(try localRepository.HEAD.target.id == remoteRepository.HEAD.target.id)

        // Upstream branch should be nil
        #expect(try localRepository.branch.current.upstream == nil)

        // Set the upstream branch
        try localRepository.branch.setUpstream(to: localRepository.branch.get(named: "origin/main"))

        // Check if the upstream branch is set
        let upstreamBranch = try #require(localRepository.branch.current.upstream as? Branch)
        #expect(upstreamBranch.target.id == (try remoteRepository.HEAD.target.id))
        #expect(upstreamBranch.name == "origin/main")
        #expect(upstreamBranch.fullName == "refs/remotes/origin/main")
    }
}
