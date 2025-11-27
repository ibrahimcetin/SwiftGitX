import SwiftGitX
import Testing

@Suite("Repository - Add", .tags(.repository, .operation, .add))
final class RepositoryAddTests: SwiftGitXTest {
    @Test("Add file to index")
    func addFile() async throws {
        let repository = mockRepository()

        // Create a file
        let file = try repository.mockFile()

        // Add to index
        try repository.add(file: file)

        // Verify status
        let status = try repository.status(file: file)
        #expect(status == [.indexNew])
    }
}
