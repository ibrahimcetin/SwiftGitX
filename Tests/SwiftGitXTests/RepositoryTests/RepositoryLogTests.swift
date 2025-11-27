import SwiftGitX
import Testing

@Suite("Repository - Log", .tags(.repository, .operation, .log))
final class RepositoryLogTests: SwiftGitXTest {
    @Test("Log returns commits in order")
    func log() async throws {
        let repository = mockRepository()

        // Create multiple commits
        let commits = try (0..<10).map { _ in try repository.mockCommit() }

        // Get log with reverse sorting
        let commitSequence = try repository.log(from: repository.HEAD, sorting: .reverse)
        let logCommits = Array(commitSequence)
        #expect(logCommits == commits)
    }
}
