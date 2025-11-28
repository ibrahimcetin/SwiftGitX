import Foundation
import SwiftGitX
import Testing

@Suite("Repository - Properties", .tags(.repository))
final class RepositoryPropertyTests: SwiftGitXTest {
    @Test("Repository HEAD")
    func repositoryHEAD() async throws {
        let repository = mockRepository()

        // Commit the file
        let commit = try repository.mockCommit()

        // Get the HEAD reference
        let head = try repository.HEAD

        // Check the HEAD reference
        #expect(head.name == "main")
        #expect(head.fullName == "refs/heads/main")
        #expect(head.target.id == commit.id)
    }

    @Test("Repository detached HEAD")
    func repositoryDetachedHEAD() async throws {
        let repository = mockRepository()
        let commit = try repository.mockCommit()

        // Switch to commit
        try repository.switch(to: commit)

        // Get the HEAD branch
        let head = try #require(try repository.HEAD as? Branch)

        // Check the HEAD reference
        #expect(head.name == "HEAD")
        #expect(head.fullName == "HEAD")
        #expect(head.target.id == commit.id)
        #expect(head.type == .local)
    }

    @Test("Repository HEAD unborn")
    func repositoryHEADUnborn() async throws {
        let repository = mockRepository()

        #expect(repository.isHEADUnborn)

        let error = #expect(throws: SwiftGitXError.self) {
            try repository.HEAD
        }

        #expect(error?.code == .unbornBranch)
        #expect(error?.category == .reference)
        #expect(error?.message == "reference 'refs/heads/main' not found")
    }

    @Test("Repository working directory")
    func repositoryWorkingDirectory() async throws {
        let repository = mockRepository()

        // Get the working directory of the repository
        let repositoryWorkingDirectory = try repository.workingDirectory

        // The working directory should exist and be valid
        #expect(repositoryWorkingDirectory.hasDirectoryPath)
        #expect(repositoryWorkingDirectory.lastPathComponent != ".git")

        // Expected path for the repository working directory
        let expectedWorkingDirectory = URL.temporaryDirectory
            .appending(component: "SwiftGitXTests")
            .appending(components: "RepositoryPropertyTests", "RepositoryPropertyTests", "repositoryWorkingDirectory/")

        #expect(repositoryWorkingDirectory.resolvingSymlinksInPath() == expectedWorkingDirectory)
    }

    @Test("Repository path")
    func repositoryPath() async throws {
        let repository = mockRepository()

        // The repository path should point to the .git directory
        #expect(repository.path.lastPathComponent == ".git")
        #expect(repository.path.hasDirectoryPath)

        // Expected path for the repository working directory
        let expectedPath = URL.temporaryDirectory
            .appending(component: "SwiftGitXTests")
            .appending(components: "RepositoryPropertyTests", "RepositoryPropertyTests", "repositoryPath", ".git/")

        #expect(repository.path.resolvingSymlinksInPath() == expectedPath)
    }

    @Test("Repository path for bare repository")
    func repositoryPathBare() async throws {
        let repository = mockRepository(isBare: true)

        // For bare repositories, the path should not end with .git
        #expect(repository.path.lastPathComponent != ".git")
        #expect(repository.path.hasDirectoryPath)

        // Expected path for the repository path
        let expectedPath = URL.temporaryDirectory
            .appending(component: "SwiftGitXTests")
            .appending(components: "RepositoryPropertyTests", "RepositoryPropertyTests", "repositoryPathBare/")

        #expect(repository.path.resolvingSymlinksInPath() == expectedPath)

        // Bare repositories don't have a working directory
        let error = #expect(throws: SwiftGitXError.self) {
            try repository.workingDirectory
        }

        #expect(error?.code == .error)
        #expect(error?.category == .repository)
        #expect(error?.message == "Failed to get working directory")
    }

    @Test("Repository is empty")
    func repositoryIsEmpty() async throws {
        let repository = mockRepository()

        // Check if the repository is empty
        #expect(repository.isEmpty)

        // Create a commit
        try repository.mockCommit()

        // Check if the repository is not empty
        #expect(repository.isEmpty == false)
    }
}
