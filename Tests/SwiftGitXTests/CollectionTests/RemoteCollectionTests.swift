import Foundation
import SwiftGitX
import Testing

@Suite("Remote Collection", .tags(.remote, .collection))
final class RemoteCollectionTests: SwiftGitXTest {
    @Test("Lookup remote by name")
    func remoteLookup() async throws {
        let repository = mockRepository()

        // Add a remote to the repository
        let url = URL(string: "https://github.com/username/repo.git")!
        let remote = try repository.remote.add(named: "origin", at: url)

        // Get the remote from the repository
        let remoteLookup = try repository.remote.get(named: "origin")

        // Check if the remote is the same
        #expect(remoteLookup == remote)
        #expect(remote.name == "origin")
        #expect(remote.url == url)
    }

    @Test("Add remote to repository")
    func remoteAdd() async throws {
        let repository = mockRepository()

        // Add a new remote to the repository
        let url = URL(string: "https://github.com/ibrahimcetin/SwiftGitX.git")!
        let remote = try repository.remote.add(named: "origin", at: url)

        // Get the remote from the repository
        let remoteLookup = try repository.remote.get(named: "origin")

        // Check if the remote is the same
        #expect(remoteLookup == remote)
        #expect(remote.name == "origin")
        #expect(remote.url == url)
    }

    @Test("Get remote branches after clone")
    func remoteBranches() async throws {
        let remoteRepository = mockRepository()

        // Create a commit in the repository
        try remoteRepository.mockCommit()

        // Create branches in the repository
        for name in ["feature/1", "feature/2", "feature/3", "feature/4", "feature/5", "feature/6", "feature/7"] {
            try remoteRepository.branch.create(named: name, from: remoteRepository.branch.current)
        }
        let branches = Array(remoteRepository.branch.local)

        #expect(branches.count == 8)

        // Clone remote repository to local repository
        let localDirectory = mockDirectory(suffix: "--local")
        let localRepository = try await Repository.clone(from: remoteRepository.workingDirectory, to: localDirectory)

        // Get the remote from the repository excluding the main branch
        let remoteBranches = Array(localRepository.branch.remote.filter { $0.referenceType == .direct })

        // Check if the branches are the same
        #expect(remoteBranches.count == 8)

        for (remoteBranch, branch) in zip(remoteBranches, branches) {
            #expect(remoteBranch.name == "origin/" + branch.name)
        }
    }

    @Test("Remove remote from repository")
    func remoteRemove() async throws {
        let repository = mockRepository()

        // Add a remote to the repository
        let remote = try repository.remote.add(
            named: "origin",
            at: URL(string: "https://github.com/ibrahimcetin/SwiftGitX.git")!
        )

        // Remove the remote from the repository
        try repository.remote.remove(remote)

        // Get the remote from the repository (should throw)
        let error = #expect(throws: SwiftGitXError.self) {
            try repository.remote.get(named: "origin")
        }

        #expect(error?.code == .notFound)
        #expect(error?.category == .config)
        #expect(error?.message == "remote \'origin\' does not exist")
    }

    @Test("List all remotes")
    func remoteList() async throws {
        let repository = mockRepository()

        // Add remotes to the repository
        let remoteNames = ["origin", "upstream", "features", "my-remote", "remote"]
        let remotes = try remoteNames.map { name in
            try repository.remote.add(named: name, at: URL(string: "https://example.com/\(name).git")!)
        }

        // List the remotes in the repository
        let remoteLookups = try repository.remote.list()

        #expect(Set(remotes) == Set(remoteLookups))
    }

    @Test("List remotes on empty repository returns empty array")
    func remoteListEmpty() async throws {
        let repository = mockRepository()

        // List remotes (should be empty)
        let remotes = try repository.remote.list()

        #expect(remotes.isEmpty)
    }

    @Test("Iterate over all remotes")
    func remoteIterator() async throws {
        let repository = mockRepository()

        // Add remotes to the repository
        let remoteNames = ["origin", "upstream", "features", "my-remote", "remote"]
        let remotes = try remoteNames.map { name in
            try repository.remote.add(named: name, at: URL(string: "https://example.com/\(name).git")!)
        }

        // List the remotes in the repository
        let remoteLookups = Array(repository.remote)

        #expect(Set(remotes) == Set(remoteLookups))
    }

    @Test("Iterate over empty repository returns no remotes")
    func remoteIteratorEmpty() async throws {
        let repository = mockRepository()

        // Iterate over remotes (should be empty)
        let remotes = Array(repository.remote)

        #expect(remotes.isEmpty)
    }

    @Test("Lookup non-existent remote throws error")
    func remoteLookupNotFound() async throws {
        let repository = mockRepository()

        // Get the remote (should throw)
        let error = #expect(throws: SwiftGitXError.self) {
            try repository.remote.get(named: "origin")
        }

        #expect(error?.code == .notFound)
        #expect(error?.category == .config)
        #expect(error?.message == "remote \'origin\' does not exist")
    }

    @Test("Add duplicate remote throws error")
    func remoteAddFailure() async throws {
        let repository = mockRepository()

        // Add a remote to the repository
        let remote = try repository.remote.add(
            named: "origin",
            at: URL(string: "https://github.com/ibrahimcetin/SwiftGitX.git")!
        )

        // Add the same remote again (should throw)
        let error = #expect(throws: SwiftGitXError.self) {
            try repository.remote.add(named: "origin", at: remote.url)
        }

        #expect(error?.code == .exists)
        #expect(error?.category == .config)
        #expect(error?.message == "remote \'origin\' already exists")
    }

    @Test("Remove non-existent remote throws error")
    func remoteRemoveFailure() async throws {
        let repository = mockRepository()

        // Add a remote to the repository
        let remote = try repository.remote.add(
            named: "origin",
            at: URL(string: "https://github.com/ibrahimcetin/SwiftGitX.git")!
        )

        // Remove the remote from the repository
        try repository.remote.remove(remote)

        // Remove the remote again (should throw)
        let error = #expect(throws: SwiftGitXError.self) {
            try repository.remote.remove(remote)
        }

        #expect(error?.code == .notFound)
        #expect(error?.category == .config)
        #expect(error?.message == "remote \'origin\' does not exist")
    }

    @Test("Lookup remote using subscript")
    func remoteSubscriptLookup() async throws {
        let repository = mockRepository()

        // Add a remote to the repository
        let url = URL(string: "https://github.com/username/repo.git")!
        let remote = try repository.remote.add(named: "origin", at: url)

        // Get the remote using subscript
        let remoteLookup = repository.remote["origin"]

        // Check if the remote is the same
        #expect(remoteLookup == remote)
        #expect(remoteLookup?.name == "origin")
        #expect(remoteLookup?.url == url)
    }

    @Test("Lookup non-existent remote using subscript returns nil")
    func remoteSubscriptNotFound() async throws {
        let repository = mockRepository()

        // Get the remote using subscript (should return nil)
        let remote = repository.remote["nonexistent"]

        #expect(remote == nil)
    }

}
