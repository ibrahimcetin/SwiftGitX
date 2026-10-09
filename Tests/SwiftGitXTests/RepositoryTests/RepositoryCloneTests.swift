import Foundation
import SwiftGitX
import Testing

@Suite("Repository - Clone", .tags(.repository, .operation, .clone))
final class RepositoryCloneTests: SwiftGitXTest {
    @Test("Repository clone")
    func repositoryClone() async throws {
        // Create a temporary URL for the source repository
        let source = mockCloneSource(suffix: "--basic").path

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
        #if os(macOS)
        let sourceRepository = mockCloneSource(suffix: "--cancel")

        // Create a temporary directory for the destination repository
        let directory = mockDirectory()

        try await withGitDaemon(for: sourceRepository) { source in
            var startContinuation: AsyncStream<Void>.Continuation!
            let startSignal = AsyncStream<Void> { startContinuation = $0 }
            let task = Task {
                for await _ in startSignal { break }
                _ = try await Repository.clone(from: source, to: directory)
            }

            task.cancel()
            startContinuation.yield(())
            startContinuation.finish()

            let result = await task.result
            #expect(task.isCancelled)
            guard case .failure = result else {
                Issue.record("The task should be cancelled.")
                return
            }

            #expect(FileManager.default.fileExists(atPath: directory.path) == false)
        }
        #endif
    }

    @Test("Repository clone with progress")
    func repositoryCloneWithProgress() async throws {
        // Create source URL for the repository
        let source = mockCloneSource(suffix: "--progress").path

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
        #if os(macOS)
        let sourceRepository = mockCloneSource(suffix: "--progress-cancel")

        // Create a temporary directory for the destination repository
        let directory = mockDirectory()

        try await withGitDaemon(for: sourceRepository) { source in
            var startContinuation: AsyncStream<Void>.Continuation!
            let startSignal = AsyncStream<Void> { startContinuation = $0 }
            let task = Task {
                for await _ in startSignal { break }
                _ = try await Repository.clone(from: source, to: directory) { _ in }
            }

            task.cancel()
            startContinuation.yield(())
            startContinuation.finish()

            let result = await task.result
            #expect(task.isCancelled)
            guard case .failure = result else {
                Issue.record("The task should be cancelled.")
                return
            }

            #expect(FileManager.default.fileExists(atPath: directory.path) == false)
        }
        #endif
    }
}
