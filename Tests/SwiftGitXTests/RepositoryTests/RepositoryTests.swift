import SwiftGitX
import XCTest

extension Repository {
    static var testsDirectory: URL {
        URL.temporaryDirectory.appending(components: "SwiftGitXTests")
    }

    /// Creates a new mock repository at the temporary directory with the given name.
    ///
    /// - Parameters
    ///   - name: The name of the mock repository to create.
    ///   - parentDirectoryName: The name of the parent directory to create the repository in.
    ///
    /// - Returns: The created repository.
    static func mock(named name: String, in parentDirectoryName: String, isBare: Bool = false) -> Repository {
        do {
            let directory = mockDirectory(named: name, in: parentDirectoryName)

            // Create a new repository at the temporary directory
            return try Repository.create(at: directory, isBare: isBare)
        } catch {
            fatalError("Failed to create a mock repository: \(error)")
        }
    }

    /// Creates an empty directory with the given name in the temporary directory.
    ///
    /// - Parameters
    ///   - name: The name of the directory to create.
    ///   - parentDirectoryName: The name of the parent directory to create the directory in.
    ///   - create: Whether to create the directory or not.
    ///
    /// - Returns: The URL of the directory.
    ///
    /// If the directory already exists, it always will be removed.
    /// If the `create` parameter is set to `true`, the directory will be created.
    /// Otherwise, only the URL of the empty directory will be returned.
    static func mockDirectory(named name: String, in parentDirectoryName: String, create: Bool = false) -> URL {
        do {
            // Create a new directory url in the temporary directory
            let directory =
                if parentDirectoryName.isEmpty {
                    Self.testsDirectory.appending(components: name)
                } else {
                    Self.testsDirectory.appending(components: parentDirectoryName, name)
                }

            // Remove the directory if it already exists to create an empty repository
            if FileManager.default.fileExists(atPath: directory.path) {
                try FileManager.default.removeItem(at: directory)
            }

            // Create the directory
            if create {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
            }

            return directory
        } catch {
            fatalError("Failed to create a mock directory: \(error)")
        }
    }

    /// Creates a mock file in the repository.
    ///
    /// - Parameter name: The name of the file
    func mockFile(named name: String, content: String? = nil) throws -> URL {
        let file = try workingDirectory.appending(component: name)

        FileManager.default.createFile(
            atPath: file.path,
            contents: (content ?? "Welcome to SwiftGitX!\n").data(using: .utf8)
        )

        return file
    }

    /// Creates a mock commit in the repository.
    @discardableResult
    func mockCommit(message: String? = nil, file: URL? = nil) throws -> Commit {
        // Add the file to the index
        try add(file: file ?? mockFile(named: "README.md"))

        // Commit the changes
        return try commit(message: message ?? "Initial commit")
    }
}

final class RepositoryTests: SwiftGitXTestCase {
    func testRepositoryInit() throws {
        // Create a temporary directory for the repository
        let directory = Repository.mockDirectory(named: "test-init", in: Self.directory)

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
        XCTAssertEqual(commit, headCommit)
    }

    func testRepositoryCreate() {
        // Create a temporary directory for the repository
        let directory = Repository.mockDirectory(named: "test-create", in: Self.directory)

        // Create a new repository at the temporary directory
        XCTAssertNoThrow(try Repository.create(at: directory))

        // Check if the repository opens without any errors
        XCTAssertNoThrow(try Repository(at: directory))
    }

    func testRepositoryCreateBare() throws {
        // Create a temporary directory for the repository
        let directory = Repository.mockDirectory(named: "test-create-bare", in: Self.directory)

        // Create a new repository at the temporary directory
        XCTAssertNoThrow(try Repository.create(at: directory, isBare: true))

        // Check if the repository opens without any errors
        let repository = try Repository(at: directory)

        // Check if the repository is bare
        XCTAssertTrue(repository.isBare)
    }

    func testRepositoryOpen() {
        // Create a temporary directory for the repository
        let directory = Repository.mockDirectory(named: "test-open", in: Self.directory)

        // Create a new repository at the temporary directory
        XCTAssertNoThrow(try Repository.create(at: directory))

        // Check if the repository opens without any errors
        XCTAssertNoThrow(try Repository.open(at: directory))
    }

    func testRepositoryOpenFailure() {
        // Create a temporary directory for the repository
        let directory = Repository.mockDirectory(named: "test-non-existent", in: Self.directory, create: true)

        // Try to create a repository at a non-existent directory
        try XCTAssertThrowsError(Repository.open(at: directory))
    }

    func testRepositoryClone() async throws {
        // Create a temporary URL for the source repository
        let source = URL(string: "https://github.com/ibrahimcetin/SwiftGitX.git")!

        // Create a temporary directory for the destination repository
        let directory = Repository.mockDirectory(named: "test-clone", in: Self.directory)

        // Perform the clone operation
        _ = try await Repository.clone(from: source, to: directory)

        // Check if the destination repository exists
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.path))

        // Check if the repository opens without any errors
        XCTAssertNoThrow(try Repository(at: directory))
    }

    func testRepositoryCloneCancellation() async {
        // Create a temporary URL for the source repository
        let source = URL(string: "https://github.com/ibrahimcetin/SwiftGitX.git")!

        // Create a temporary directory for the destination repository
        let directory = Repository.mockDirectory(named: "test-clone-cancellation", in: Self.directory)

        // Perform the clone operation
        let task = Task {
            try await Repository.clone(from: source, to: directory)
        }

        // Cancel the task
        task.cancel()

        // Wait for the task to complete
        let result = await task.result

        // Check if the task is cancelled
        XCTAssertTrue(task.isCancelled)

        // Check if the task result is a failure
        guard case .failure = result else {
            XCTFail("The task should be cancelled.")
            return
        }

        // Check if the destination repository exists
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.path))
    }

    func testRepositoryCloneWithProgress() async throws {
        // Create source URL for the repository
        let source = URL(string: "https://github.com/ibrahimcetin/SwiftGitX.git")!

        // Create a temporary directory for the destination repository
        let directory = Repository.mockDirectory(named: "test-clone-progress", in: Self.directory)

        let progressExpectation = expectation(description: "Cloning progress")

        // Perform the clone operation
        _ = try await Repository.clone(from: source, to: directory) { progress in
            guard progress.indexedDeltas == progress.totalDeltas else { return }

            guard progress.receivedObjects == progress.totalObjects else { return }

            guard progress.indexedObjects == progress.totalObjects else { return }

            progressExpectation.fulfill()
        }

        // Wait for the progress to complete
        await fulfillment(of: [progressExpectation], timeout: 60)

        // Check if the destination repository exists
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.path))

        // Check if the repository opens without any errors
        XCTAssertNoThrow(try Repository(at: directory))
    }

    func testRepositoryCloneWithProgressCancellation() async throws {
        // Create source URL for the repository
        let source = URL(string: "https://github.com/ibrahimcetin/SwiftGitX.git")!

        // Create a temporary directory for the destination repository
        let directory = Repository.mockDirectory(named: "test-clone-progress-cancellation", in: Self.directory)

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
        XCTAssertTrue(task.isCancelled)

        // Check if the task result is a failure
        guard case .failure = result else {
            XCTFail("The task should be cancelled.")
            return
        }

        // Check if the destination repository exists
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.path))
    }

    func testRepositoryCodable() throws {
        // Create a repository at the temporary directory
        let repository = Repository.mock(named: "test-codable", in: Self.directory)

        // Create a new commit
        try repository.mockCommit()

        // Encode the repository
        let data = try JSONEncoder().encode(repository)

        // Decode the repository
        let decodedRepository = try JSONDecoder().decode(Repository.self, from: data)

        // Check if the decoded repository HEAD is the same as the original repository HEAD
        try XCTAssertEqual(repository.HEAD as! Branch, decodedRepository.HEAD as! Branch)
    }

    func testRepositoryEquatable() throws {
        // Create a repository at the temporary directory
        let repository = Repository.mock(named: "test-equatable", in: Self.directory)

        // Create a new commit
        try repository.mockCommit()

        // Create a new repository with the same directory
        let anotherRepository = try Repository(at: repository.path)

        // Check if the repository HEADs are the same
        try XCTAssertEqual(repository.HEAD as! Branch, anotherRepository.HEAD as! Branch)

        // Check if the repositories are equal
        XCTAssertEqual(repository, anotherRepository)
    }

    func testRepositoryHashable() throws {
        // Create a repository at the temporary directory
        let repository = Repository.mock(named: "test-hashable", in: Self.directory)

        // Create a new commit
        try repository.mockCommit()

        // Create a new repository with the same directory
        let anotherRepository = try Repository(at: repository.path)

        // Check if the repository HEADs are the same
        try XCTAssertEqual(repository.HEAD as! Branch, anotherRepository.HEAD as! Branch)

        // Check if the repositories have the same hash value
        XCTAssertEqual(repository.hashValue, anotherRepository.hashValue)
    }
}
