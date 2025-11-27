import Foundation
import SwiftGitX
import Testing

extension Repository {
    /// Creates a mock file in the repository.
    ///
    /// - Parameters:
    ///   - name: The name of the file. If nil, generates a unique sequential name.
    ///   - content: The content of the file. If nil, generates sequential content.
    ///
    /// - Returns: The URL of the created file.
    func mockFile(name: String? = nil, content: String? = nil) throws -> URL {
        // Count existing files in working directory to determine sequence number
        let existingFiles = try FileManager.default.contentsOfDirectory(
            at: workingDirectory,
            includingPropertiesForKeys: nil
        ).filter { !$0.lastPathComponent.hasPrefix(".") }  // Exclude hidden files

        let sequenceNumber = existingFiles.count + 1

        // Generate a unique file name if none is provided
        let fileName = name ?? "file-\(sequenceNumber).txt"

        // Generate sequential content if none is provided
        let fileContent = content ?? "File \(sequenceNumber) content\n"

        let file = try workingDirectory.appending(component: fileName)

        FileManager.default.createFile(
            atPath: file.path,
            contents: fileContent.data(using: .utf8)
        )

        return file
    }

    /// Creates a mock commit in the repository.
    @discardableResult
    func mockCommit(message: String? = nil, file: URL? = nil) throws -> Commit {
        // Count existing commits to determine the sequence number
        let commitCount = (try? log().reduce(0) { count, _ in count + 1 }) ?? 0
        let sequenceNumber = commitCount + 1

        // Generate a unique file if none is provided to ensure we always have changes to commit
        let fileToAdd = try file ?? mockFile(name: "file-\(sequenceNumber).txt")

        // Add the file to the index
        try add(file: fileToAdd)

        // Determine the commit message based on sequence
        let commitMessage = message ?? "Commit #\(sequenceNumber)"

        // Commit the changes
        return try commit(message: commitMessage)
    }
}

// MARK: - Repository Initialization

@Suite("Repository - Initialization", .tags(.repository))
final class RepositoryInitializationTests: SwiftGitXTest {
    @Test("Repository init creates or opens repository")
    func repositoryInit() async throws {
        // Create a temporary directory for the repository
        let directory = mockDirectory()

        // This should create a new repository at the empty directory
        let repositoryCreated = try Repository(at: directory)

        // Create a new commit
        let commit = try repositoryCreated.mockCommit()

        // This should open the existing repository
        let repositoryOpened = try Repository(at: directory)

        // Get the HEAD commit
        let head = try repositoryOpened.HEAD
        let headCommit: Commit = try repositoryOpened.show(id: head.target.id)

        // Check if the HEAD commit is the same as the created commit
        // This checks if the repository was created and opened successfully
        // This also ensures that the second call to `Repository(at:)` opens the existing repository
        #expect(commit == headCommit)
    }

    @Test("Repository create")
    func repositoryCreate() async throws {
        // Create a temporary directory for the repository
        let directory = mockDirectory()

        // Create a new repository at the temporary directory
        _ = try Repository.create(at: directory)

        // Check if the repository opens without any errors
        _ = try Repository(at: directory)
    }

    @Test("Repository create bare")
    func repositoryCreateBare() async throws {
        // Create a temporary directory for the repository
        let directory = mockDirectory()

        // Create a new repository at the temporary directory
        _ = try Repository.create(at: directory, isBare: true)

        // Check if the repository opens without any errors
        let repository = try Repository(at: directory)

        // Check if the repository is bare
        #expect(repository.isBare)
    }

    @Test("Repository open")
    func repositoryOpen() async throws {
        // Create a temporary directory for the repository
        let directory = mockDirectory()

        // Create a new repository at the temporary directory
        _ = try Repository.create(at: directory)

        // Check if the repository opens without any errors
        _ = try Repository.open(at: directory)
    }

    @Test("Repository open failure")
    func repositoryOpenFailure() async throws {
        // Create a temporary directory for the repository
        let directory = mockDirectory()

        // Try to open a repository at a non-repository directory
        #expect(throws: SwiftGitXError.self) {
            try Repository.open(at: directory)
        }
    }
}

// MARK: - Repository Protocols

@Suite("Repository - Protocols", .tags(.repository))
final class RepositoryProtocolTests: SwiftGitXTest {
    @Test("Repository Codable")
    func repositoryCodable() async throws {
        // Create a repository at the temporary directory
        let repository = mockRepository()

        // Create a new commit
        try repository.mockCommit()

        // Encode the repository
        let data = try JSONEncoder().encode(repository)

        // Decode the repository
        let decodedRepository = try JSONDecoder().decode(Repository.self, from: data)

        // Check if the decoded repository HEAD is the same as the original repository HEAD
        #expect(try (repository.HEAD as! Branch) == (decodedRepository.HEAD as! Branch))
    }

    @Test("Repository Equatable")
    func repositoryEquatable() async throws {
        // Create a repository at the temporary directory
        let repository = mockRepository()

        // Create a new commit
        try repository.mockCommit()

        // Create a new repository with the same directory
        let anotherRepository = try Repository(at: repository.path)

        // Check if the repository HEADs are the same
        #expect(try (repository.HEAD as! Branch) == (anotherRepository.HEAD as! Branch))

        // Check if the repositories are equal
        #expect(repository == anotherRepository)
    }

    @Test("Repository Hashable")
    func repositoryHashable() async throws {
        // Create a repository at the temporary directory
        let repository = mockRepository()

        // Create a new commit
        try repository.mockCommit()

        // Create a new repository with the same directory
        let anotherRepository = try Repository(at: repository.path)

        // Check if the repository HEADs are the same
        #expect(try (repository.HEAD as! Branch) == (anotherRepository.HEAD as! Branch))

        // Check if the repositories have the same hash value
        #expect(repository.hashValue == anotherRepository.hashValue)
    }
}
