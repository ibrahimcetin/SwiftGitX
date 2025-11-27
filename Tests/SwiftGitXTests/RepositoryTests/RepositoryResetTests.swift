import SwiftGitX
import Testing

@Suite("Repository - Reset", .tags(.repository, .operation, .reset))
final class RepositoryResetTests: SwiftGitXTest {
    @Test("Reset staged file")
    func resetStagedFile() async throws {
        let repository = mockRepository()
        let initialCommit = try repository.mockCommit()

        // Create and stage a file
        let file = try repository.mockFile()
        try repository.add(file: file)

        #expect(try repository.status(file: file) == [.indexNew])

        // Reset the staged file
        try repository.reset(from: initialCommit, files: [file])

        // File should be untracked now
        let status = try repository.status(file: file)
        #expect(status == [.workingTreeNew])
    }

    @Test("Soft reset to previous commit")
    func resetSoft() async throws {
        let repository = mockRepository()
        let initialCommit = try repository.mockCommit()

        // Create another commit
        try repository.mockCommit()

        // Reset to initial commit
        try repository.reset(to: initialCommit)

        // HEAD should point to initial commit
        let headCommit = try #require(repository.HEAD.target as? Commit)
        #expect(headCommit == initialCommit)
    }
}
