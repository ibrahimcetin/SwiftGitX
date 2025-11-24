import SwiftGitX
import XCTest

final class RemoteCollectionTests: SwiftGitXTestCase {
    func testRemoteLookup() throws {
        // Create a mock repository at the temporary directory
        let repository = Repository.mock(named: "test-remote-lookup", in: Self.directory)

        // Add a remote to the repository
        let url = URL(string: "https://github.com/username/repo.git")!
        let remote = try repository.remote.add(named: "origin", at: url)

        // Get the remote from the repository
        let remoteLookup = try repository.remote.get(named: "origin")

        // Check if the remote is the same
        XCTAssertEqual(remoteLookup, remote)

        XCTAssertEqual(remote.name, "origin")
        XCTAssertEqual(remote.url, url)
    }

    func testRemoteAdd() throws {
        // Create a mock repository at the temporary directory
        let repository = Repository.mock(named: "test-remote-add", in: Self.directory)

        // Add a new remote to the repository
        let url = URL(string: "https://github.com/ibrahimcetin/SwiftGitX.git")!
        let remote = try repository.remote.add(named: "origin", at: url)

        // Get the remote from the repository
        let remoteLookup = try repository.remote.get(named: "origin")

        // Check if the remote is the same
        XCTAssertEqual(remoteLookup, remote)

        XCTAssertEqual(remote.name, "origin")
        XCTAssertEqual(remote.url, url)
    }

    func testRemoteBranches() async throws {
        // Create a mock repository at the temporary directory
        let remoteRepository = Repository.mock(named: "test-remote-branches--remote", in: Self.directory)

        // Create a commit in the repository
        try remoteRepository.mockCommit()

        // Create branches in the repository
        try ["feature/1", "feature/2", "feature/3", "feature/4", "feature/5", "feature/6", "feature/7"]
            .forEach { name in
                try remoteRepository.branch.create(named: name, from: remoteRepository.branch.current)
            }
        let branches = Array(remoteRepository.branch.local)

        XCTAssertEqual(branches.count, 8)

        // Clone remote repository to local repository
        let localDirectory = Repository.mockDirectory(named: "test-remote-branches--local", in: Self.directory)
        let localRepository = try await Repository.clone(from: remoteRepository.workingDirectory, to: localDirectory)

        // Get the remote from the repository excluding the main branch
        let remoteBranches = Array(localRepository.branch.remote)

        // Check if the branches are the same
        XCTAssertEqual(remoteBranches.count, 8)

        for (remoteBranch, branch) in zip(remoteBranches, branches) {
            XCTAssertEqual(remoteBranch.name, "origin/" + branch.name)
        }
    }

    func testRemoteRemove() throws {
        // Create a mock repository at the temporary directory
        let repository = Repository.mock(named: "test-remote-remove", in: Self.directory)

        // Add a remote to the repository
        let remote = try repository.remote.add(
            named: "origin",
            at: URL(string: "https://github.com/ibrahimcetin/SwiftGitX.git")!
        )

        // Remove the remote from the repository
        try repository.remote.remove(remote)

        // Get the remote from the repository
        XCTAssertThrowsError(try repository.remote.get(named: "origin")) { error in
            XCTAssertTrue(error is SwiftGitXError)

            let error = error as? SwiftGitXError

            XCTAssertEqual(error?.code, .notFound)
            XCTAssertEqual(error?.category, .config)
            XCTAssertEqual(error?.message, "remote \'origin\' does not exist")
        }
    }

    func testRemoteList() throws {
        // Create a mock repository at the temporary directory
        let repository = Repository.mock(named: "test-remote-list", in: Self.directory)

        // Add remotes to the repository
        let remoteNames = ["origin", "upstream", "features", "my-remote", "remote"]
        let remotes = try remoteNames.map { name in
            try repository.remote.add(named: name, at: URL(string: "https://example.com/\(name).git")!)
        }

        // List the remotes in the repository
        let remoteLookups = try repository.remote.list()

        XCTAssertEqual(Set(remotes), Set(remoteLookups))
    }

    func testRemoteIterator() throws {
        // Create a mock repository at the temporary directory
        let repository = Repository.mock(named: "test-remote-iterator", in: Self.directory)

        // Add remotes to the repository
        let remoteNames = ["origin", "upstream", "features", "my-remote", "remote"]
        let remotes = try remoteNames.map { name in
            try repository.remote.add(named: name, at: URL(string: "https://example.com/\(name).git")!)
        }

        // List the remotes in the repository
        let remoteLookups = Array(repository.remote)

        XCTAssertEqual(Set(remotes), Set(remoteLookups))
    }

    func testRemoteLookupNotFound() throws {
        // Create a new repository at the temporary directory
        let repository = Repository.mock(named: "test-remote-not-found", in: Self.directory)

        // Get the remote
        XCTAssertThrowsError(try repository.remote.get(named: "origin")) { error in
            XCTAssertTrue(error is SwiftGitXError)

            let error = error as? SwiftGitXError

            XCTAssertEqual(error?.code, .notFound)
            XCTAssertEqual(error?.category, .config)
            XCTAssertEqual(error?.message, "remote \'origin\' does not exist")
        }
    }

    func testRemoteAddFailure() throws {
        // Create a mock repository at the temporary directory
        let repository = Repository.mock(named: "test-remote-remove", in: Self.directory)

        // Add a remote to the repository
        let remote = try repository.remote.add(
            named: "origin",
            at: URL(string: "https://github.com/ibrahimcetin/SwiftGitX.git")!
        )

        // Add the same remote again
        XCTAssertThrowsError(try repository.remote.add(named: "origin", at: remote.url)) { error in
            XCTAssertEqual(error as? RemoteCollectionError, .remoteAlreadyExists("remote \'origin\' already exists"))
        }
    }

    func testRemoteRemoveFailure() throws {
        // Create a mock repository at the temporary directory
        let repository = Repository.mock(named: "test-remote-remove", in: Self.directory)

        // Add a remote to the repository
        let remote = try repository.remote.add(
            named: "origin",
            at: URL(string: "https://github.com/ibrahimcetin/SwiftGitX.git")!
        )

        // Remove the remote from the repository
        try repository.remote.remove(remote)

        // Remove the remote again
        XCTAssertThrowsError(try repository.remote.remove(remote)) { error in
            XCTAssertEqual(error as? RemoteCollectionError, .failedToRemove("remote \'origin\' does not exist"))
        }
    }
}
