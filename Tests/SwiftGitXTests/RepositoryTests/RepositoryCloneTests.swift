import Foundation
import SwiftGitX
import Testing

@Suite("Repository - Clone", .tags(.repository, .operation, .clone))
final class RepositoryCloneTests: SwiftGitXTest {
    @Test("Repository clone")
    func repositoryClone() async throws {
        // Create a temporary URL for the source repository
        let source = URL(string: "https://github.com/ibrahimcetin/SwiftGitX.git")!

        // Create a temporary directory for the destination repository
        let directory = mockDirectory()

        // Perform the clone operation
        _ = try await Repository.clone(from: source, to: directory)

        // Check if the destination repository exists
        #expect(FileManager.default.fileExists(atPath: directory.path))

        // Check if the repository opens without any errors
        _ = try Repository(at: directory)
    }

    @Test("Repository clone cancellation")
    func repositoryCloneCancellation() async throws {
        // Create a temporary URL for the source repository
        let source = URL(string: "https://github.com/ibrahimcetin/SwiftGitX.git")!

        // Create a temporary directory for the destination repository
        let directory = mockDirectory()

        // Perform the clone operation
        let task = Task {
            try await Repository.clone(from: source, to: directory)
        }

        // Cancel the task
        task.cancel()

        // Wait for the task to complete
        let result = await task.result

        // Check if the task is cancelled
        #expect(task.isCancelled)

        // Check if the task result is a failure
        guard case .failure = result else {
            Issue.record("The task should be cancelled.")
            return
        }

        // Check if the destination repository exists
        #expect(FileManager.default.fileExists(atPath: directory.path) == false)
    }

    @Test("Repository clone with progress")
    func repositoryCloneWithProgress() async throws {
        // Create source URL for the repository
        let source = URL(string: "https://github.com/ibrahimcetin/SwiftGitX.git")!

        // Create a temporary directory for the destination repository
        let directory = mockDirectory()

        var progressCompleted = false

        // Perform the clone operation
        _ = try await Repository.clone(from: source, to: directory) { progress in
            guard progress.indexedDeltas == progress.totalDeltas else { return }
            guard progress.receivedObjects == progress.totalObjects else { return }
            guard progress.indexedObjects == progress.totalObjects else { return }

            progressCompleted = true
        }

        // Check if the progress completed
        #expect(progressCompleted)

        // Check if the destination repository exists
        #expect(FileManager.default.fileExists(atPath: directory.path))

        // Check if the repository opens without any errors
        _ = try Repository(at: directory)
    }

    @Test("Repository clone with progress cancellation")
    func repositoryCloneWithProgressCancellation() async throws {
        // Create source URL for the repository
        let source = URL(string: "https://github.com/ibrahimcetin/SwiftGitX.git")!

        // Create a temporary directory for the destination repository
        let directory = mockDirectory()

        // Create a task for the clone operation
        let task = Task {
            let repository = try await Repository.clone(from: source, to: directory) { progress in
                print(progress)
            }

            return repository
        }

        // Cancel the task
        task.cancel()

        // Wait for the task to complete (shouldn't wait because cancelled)
        let result = await task.result

        // Check if the task is cancelled
        #expect(task.isCancelled)

        // Check if the task result is a failure
        guard case .failure = result else {
            Issue.record("The task should be cancelled.")
            return
        }

        // Check if the destination repository exists
        #expect(FileManager.default.fileExists(atPath: directory.path) == false)
    }
}
