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

    @Test("Create branch with force flag overwrites existing")
    func branchCreateForce() async throws {
        let repository = mockRepository()
        let commit1 = try repository.mockCommit()

        // Create initial branch
        let branch1 = try repository.branch.create(named: "develop", target: commit1)
        #expect(branch1.target.id == commit1.id)

        // Create another commit
        let commit2 = try repository.mockCommit(message: "Second commit")

        // Try to create branch without force (should fail)
        #expect(throws: SwiftGitXError.self) {
            try repository.branch.create(named: "develop", target: commit2, force: false)
        }

        // Create branch with force (should succeed and point to new commit)
        let branch2 = try repository.branch.create(named: "develop", target: commit2, force: true)
        #expect(branch2.name == "develop")
        #expect(branch2.target.id == commit2.id)
        #expect(branch2.target.id != commit1.id)
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

    @Test("Rename branch with force flag overwrites existing")
    func branchRenameForce() async throws {
        let repository = mockRepository()
        let commit = try repository.mockCommit()

        // Create two branches
        let branch1 = try repository.branch.create(named: "develop", target: commit)
        _ = try repository.branch.create(named: "feature", target: commit)

        // Try to rename without force (should fail)
        #expect(throws: SwiftGitXError.self) {
            try repository.branch.rename(branch1, to: "feature", force: false)
        }

        // Rename with force (should succeed)
        let renamedBranch = try repository.branch.rename(branch1, to: "feature", force: true)
        #expect(renamedBranch.name == "feature")

        // Check the old branch no longer exists
        #expect(repository.branch["develop"] == nil)

        // The original feature branch should be overwritten
        let featureBranch = try repository.branch.get(named: "feature")
        #expect(featureBranch.target.id == commit.id)
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

    @Test("List all branches")
    func branchListAll() async throws {
        let repository = mockRepository()

        // Create a new commit
        let commit = try repository.mockCommit()

        // Create some new branches
        let newBranchNames = ["develop", "feature"]
        for name in newBranchNames {
            try repository.branch.create(named: name, target: commit)
        }

        // Get all branches (default parameter)
        let allBranches = try repository.branch.list()
        let allBranchesExplicit = try repository.branch.list(.all)

        // Both should be equal
        #expect(allBranches.count == allBranchesExplicit.count)
        #expect(allBranches.count == 3)  // main, develop, feature

        // Check all branch types are local (since no remote yet)
        for branch in allBranches {
            #expect(branch.type == .local)
        }
    }

    @Test("Iterate all branches")
    func branchIterateAll() async throws {
        let repository = mockRepository()

        // Create a new commit
        let commit = try repository.mockCommit()

        // Create some new branches
        let newBranchNames = ["develop", "feature", "hotfix"]
        for name in newBranchNames {
            try repository.branch.create(named: name, target: commit)
        }

        // Iterate using for-in (uses makeIterator)
        var branches: [Branch] = []
        for branch in repository.branch {
            branches.append(branch)
        }

        // Check the count (including main)
        #expect(branches.count == 4)

        // Verify all branches are present
        let branchNames = branches.map(\.name).sorted()
        let expectedNames = ["develop", "feature", "hotfix", "main"]
        #expect(branchNames == expectedNames)
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

    @Test("Set upstream with explicit local branch")
    func branchSetUpstreamExplicit() async throws {
        let source = URL(string: "https://github.com/ibrahimcetin/SwiftGitX.git")!
        let directory = mockDirectory()
        let repository = try await Repository.clone(from: source, to: directory)

        // Create a new local branch from the current HEAD
        let commit = try #require(repository.HEAD.target as? Commit)
        let newBranch = try repository.branch.create(named: "feature", target: commit)

        // Set upstream for the new branch explicitly
        let upstreamBranch = try repository.branch.get(named: "origin/main")
        try repository.branch.setUpstream(from: newBranch, to: upstreamBranch)

        // Check if the upstream branch is set correctly
        let featureBranch = try repository.branch.get(named: "feature")
        let upstream = try #require(featureBranch.upstream as? Branch)
        #expect(upstream.name == "origin/main")
    }

    @Test("Iterate remote branches")
    func branchSequenceRemote() async throws {
        let source = URL(string: "https://github.com/ibrahimcetin/SwiftGitX.git")!
        let directory = mockDirectory()
        let repository = try await Repository.clone(from: source, to: directory)

        // Get the remote branches
        let remoteBranches = Array(repository.branch.remote)

        // Should have at least one remote branch (origin/main)
        #expect(!remoteBranches.isEmpty)

        // All branches should be remote type
        for branch in remoteBranches {
            #expect(branch.type == .remote)
            #expect(branch.name.hasPrefix("origin/"))
        }
    }

    @Test("List remote branches")
    func branchListRemote() async throws {
        let source = URL(string: "https://github.com/ibrahimcetin/SwiftGitX.git")!
        let directory = mockDirectory()
        let repository = try await Repository.clone(from: source, to: directory)

        // Get the remote branches
        let remoteBranches = Array(repository.branch.remote)

        // Should have at least one remote branch (origin/main)
        #expect(!remoteBranches.isEmpty)

        // All branches should be remote type
        for branch in remoteBranches {
            #expect(branch.type == .remote)
            #expect(branch.name.hasPrefix("origin/"))
        }

        // Verify we can lookup the remote branch
        let originMain = try repository.branch.get(named: "origin/main", type: .remote)
        #expect(remoteBranches.contains(originMain))
    }
}

// MARK: - Error Cases

@Suite("Branch Collection Error Cases", .tags(.branch, .collection, .error))
final class BranchCollectionErrorTests: SwiftGitXTest {
    @Test("Get non-existent branch throws error")
    func branchGetNonExistent() async throws {
        let repository = mockRepository()
        try repository.mockCommit()

        #expect(throws: SwiftGitXError.self) {
            try repository.branch.get(named: "non-existent-branch")
        }

        // Subscript should return nil
        #expect(repository.branch["non-existent-branch"] == nil)
    }

    @Test("Get current branch in detached HEAD state throws error")
    func branchCurrentDetachedHead() async throws {
        let repository = mockRepository()
        let commit = try repository.mockCommit()

        // Switch to a commit directly (creates detached HEAD)
        try repository.switch(to: commit)

        // Getting current branch should throw
        #expect(throws: SwiftGitXError.self) {
            _ = try repository.branch.current
        }
    }

    @Test("Create branch from remote branch fails")
    func branchCreateFromRemote() async throws {
        let source = URL(string: "https://github.com/ibrahimcetin/SwiftGitX.git")!
        let directory = mockDirectory()
        let repository = try await Repository.clone(from: source, to: directory)

        // Get a remote branch
        let remoteBranch = try repository.branch.get(named: "origin/main", type: .remote)

        // Try to create a branch from remote (should fail)
        #expect(throws: SwiftGitXError.self) {
            try repository.branch.create(named: "new-branch", from: remoteBranch)
        }
    }

    @Test("Delete non-existent branch fails")
    func branchDeleteNonExistent() async throws {
        let repository = mockRepository()
        try repository.mockCommit()

        // Create a branch and then lookup it to get a Branch object
        let commit = try repository.mockCommit()
        let branch = try repository.branch.create(named: "temp", target: commit)

        // Delete the branch
        try repository.branch.delete(branch)

        // Try to delete again (should fail)
        #expect(throws: SwiftGitXError.self) {
            try repository.branch.delete(branch)
        }
    }

    @Test("Rename non-existent branch fails")
    func branchRenameNonExistent() async throws {
        let repository = mockRepository()
        try repository.mockCommit()

        // Create a branch
        let commit = try repository.mockCommit()
        let branch = try repository.branch.create(named: "temp", target: commit)

        // Delete the branch
        try repository.branch.delete(branch)

        // Try to rename the deleted branch (should fail)
        #expect(throws: SwiftGitXError.self) {
            try repository.branch.rename(branch, to: "new-name")
        }
    }
}
