import Foundation
import SwiftGitX
import Testing

@Suite("Branch Collection", .tags(.branch, .collection))
final class BranchCollectionTests: SwiftGitXTest {
    @Test("Lookup branch by name")
    func branchLookup() async throws {
        let repository = mockRepository()
        let commit = try repository.mockCommit()

        let lookupBranch = try repository.branch.get(named: "main", type: .local)

        #expect(lookupBranch.name == "main")
        #expect(lookupBranch.fullName == "refs/heads/main")
        #expect(lookupBranch.target.id == commit.id)
    }

    @Test("Lookup branch using subscript")
    func branchLookupSubscript() async throws {
        let repository = mockRepository()
        let commit = try repository.mockCommit()

        let lookupBranch = try #require(repository.branch["main"])
        let lookupBranchLocal = try #require(repository.branch["main", type: .local])

        #expect(lookupBranch == lookupBranchLocal)
        #expect(lookupBranch.name == "main")
        #expect(lookupBranch.fullName == "refs/heads/main")
        #expect(lookupBranch.target.id == commit.id)

        // Lookup remote branch (should be nil)
        let lookupBranchRemote = repository.branch["main", type: .remote]
        #expect(lookupBranchRemote == nil)
    }

    @Test("Get current branch")
    func branchCurrent() async throws {
        let repository = mockRepository()
        try repository.mockCommit()

        let currentBranch = try repository.branch.current

        #expect(currentBranch.name == "main")
        #expect(currentBranch.fullName == "refs/heads/main")
        #expect(currentBranch.type == .local)
    }

    @Test("Create new branch")
    func branchCreate() async throws {
        let repository = mockRepository()
        let commit = try repository.mockCommit()

        let branch = try repository.branch.create(named: "develop", target: commit)

        #expect(branch.name == "develop")
        #expect(branch.fullName == "refs/heads/develop")
        #expect(branch.target.id == commit.id)
        #expect(branch.type == .local)
    }

    @Test("Create branch from another branch")
    func branchCreateFrom() async throws {
        let repository = mockRepository()
        try repository.mockCommit()

        let mainBranch = try repository.branch.get(named: "main")
        let newBranch = try repository.branch.create(named: "develop", from: mainBranch)

        #expect(newBranch.name == "develop")
        #expect(newBranch.fullName == "refs/heads/develop")
        #expect(newBranch.target.id == mainBranch.target.id)
        #expect(newBranch.type == .local)
    }

    @Test("Delete branch")
    func branchDelete() async throws {
        let repository = mockRepository()
        let commit = try repository.mockCommit()

        let branch = try repository.branch.create(named: "develop", target: commit)

        try repository.branch.delete(branch)

        #expect(throws: SwiftGitXError.self) {
            try repository.branch.get(named: "develop")
        }
        #expect(repository.branch["develop"] == nil)

        // Check the current branch is still main
        #expect(try repository.branch.current.name == "main")
    }

    @Test("Delete current branch fails")
    func branchDeleteCurrentFailure() async throws {
        let repository = mockRepository()
        try repository.mockCommit()

        let mainBranch = try repository.branch.get(named: "main")

        #expect(throws: SwiftGitXError.self) {
            try repository.branch.delete(mainBranch)
        }
    }

    @Test("Rename branch")
    func branchRename() async throws {
        let repository = mockRepository()
        let commit = try repository.mockCommit()

        let branch = try repository.branch.create(named: "develop", target: commit)
        let newBranch = try repository.branch.rename(branch, to: "feature")

        #expect(newBranch.name == "feature")
        #expect(newBranch.fullName == "refs/heads/feature")
        #expect(newBranch.target.id == commit.id)
        #expect(newBranch.type == .local)

        // Check the old branch no longer exists
        #expect(throws: SwiftGitXError.self) {
            try repository.branch.get(named: "develop")
        }
        #expect(repository.branch["develop"] == nil)
    }

    @Test("Iterate local branches")
    func branchSequenceLocal() async throws {
        let repository = mockRepository()

        // Get the local branches (must be empty because the main branch is unborn)
        let localBranchesEmpty = Array(repository.branch.local)
        #expect(localBranchesEmpty.isEmpty)

        // Create mock commit
        let commit = try repository.mockCommit()

        // Create some new branches
        let newBranchNames = ["other-branch", "another-branch", "one-more-branch", "last-branch"]
        for name in newBranchNames {
            try repository.branch.create(named: name, target: commit)
        }

        // Get the local branches
        let localBranches = Array(repository.branch.local)

        // Check the local branches count (including the main branch)
        #expect(localBranches.count == 5)

        // Check the local branches
        let allBranchNames = repository.branch.local.map(\.name)
        for name in allBranchNames {
            let branch = try repository.branch.get(named: name, type: .local)
            #expect(localBranches.contains(branch))
        }
    }

    @Test("List local branches")
    func branchListLocal() async throws {
        let repository = mockRepository()

        // Get the local branches (must be empty because the main branch is unborn)
        let branches = try repository.branch.list(.local)
        #expect(branches.isEmpty)

        // Create a new commit
        let commit = try repository.mockCommit()

        // Create some new branches
        let newBranchNames = ["other-branch", "another-branch", "one-more-branch", "last-branch"]
        for name in newBranchNames {
            try repository.branch.create(named: name, target: commit)
        }

        // Get the local branches
        let localBranches = try repository.branch.list(.local)

        // Check the local branches count (including the main branch)
        #expect(localBranches.count == 5)

        // Check the local branches
        let allBranchNames = localBranches.map(\.name)
        for name in allBranchNames {
            let branch = try repository.branch.get(named: name, type: .local)
            #expect(localBranches.contains(branch))
        }
    }
}

// MARK: - Remote Branch Operations

@Suite("Branch Remote Operations", .tags(.branch, .collection, .remote))
final class BranchRemoteTests: SwiftGitXTest {
    @Test("Get upstream branch")
    func branchGetUpstream() async throws {
        let source = URL(string: "https://github.com/ibrahimcetin/SwiftGitX.git")!
        let directory = mockDirectory()
        let repository = try await Repository.clone(from: source, to: directory)

        let upstreamBranch = try #require(repository.branch.current.upstream as? Branch)

        #expect(upstreamBranch.name == "origin/main")
        #expect(upstreamBranch.fullName == "refs/remotes/origin/main")
        #expect(upstreamBranch.type == .remote)
    }

    @Test("Set upstream branch")
    func branchSetUpstream() async throws {
        let source = URL(string: "https://github.com/ibrahimcetin/SwiftGitX.git")!
        let directory = mockDirectory()
        let repository = try await Repository.clone(from: source, to: directory)

        // Unset the existing upstream branch
        try repository.branch.setUpstream(to: nil)

        // Be sure that the upstream branch is unset
        #expect(try repository.branch.current.upstream == nil)

        // Set the upstream branch
        try repository.branch.setUpstream(to: repository.branch.get(named: "origin/main"))

        // Check if the upstream branch is set
        let upstreamBranch = try #require(repository.branch.current.upstream as? Branch)
        #expect(upstreamBranch.name == "origin/main")
        #expect(upstreamBranch.fullName == "refs/remotes/origin/main")
    }

    @Test("Unset upstream branch")
    func branchUnsetUpstream() async throws {
        let source = URL(string: "https://github.com/ibrahimcetin/SwiftGitX.git")!
        let directory = mockDirectory()
        let repository = try await Repository.clone(from: source, to: directory)

        // Be sure that the upstream branch is set
        #expect(try repository.branch.current.upstream != nil)

        // Unset the upstream branch
        try repository.branch.setUpstream(to: nil)

        // Check if the upstream branch is unset
        #expect(try repository.branch.current.upstream == nil)
    }
}

// MARK: - Tag Extensions

extension Testing.Tag {
    @Tag static var branch: Self
    @Tag static var collection: Self
    @Tag static var remote: Self
}
