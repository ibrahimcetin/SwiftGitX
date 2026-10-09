import Foundation
import SwiftGitX
import Testing

@Suite("Repository - Fetch", .tags(.repository, .operation, .fetch))
final class RepositoryFetchTests: SwiftGitXTest {
    @Test("Fetch from remote repository")
    func fetchFromRemote() async throws {
        // Create remote repository
        let remoteRepository = mockCloneSource(suffix: "--fetch")

        // Create local repository
        let localRepository = mockRepository(suffix: "--local")

        // Add remote repository to the local repository
        try localRepository.remote.add(named: "origin", at: remoteRepository.workingDirectory)

        // Fetch the commit from the remote repository
        try await localRepository.fetch()

        // Check if the remote branch is fetched
        let remoteBranch = try localRepository.branch.get(named: "origin/main")
        #expect(try remoteBranch.target.id == remoteRepository.HEAD.target.id)
    }
}
