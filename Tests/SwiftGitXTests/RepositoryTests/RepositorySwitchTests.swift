import Foundation
import SwiftGitX
import Testing

@Suite("Repository - Switch", .tags(.repository, .operation, .switch))
final class RepositorySwitchTests: SwiftGitXTest {
    @Test("Switch to Branch")
    func switchBranch() throws {
        // Create a new repository at the temporary directory
        let repository = mockRepository()
        let commit = try repository.mockCommit()

        // Create a new branch
        let branch = try repository.branch.create(named: "feature", target: commit)

        // Switch the new branch
        try repository.switch(to: branch)

        // Get the HEAD reference
        let head = try repository.HEAD

        // Check the HEAD reference
        #expect(head.name == branch.name)
        #expect(head.fullName == branch.fullName)
    }

    @Test("Switch to Remote Branch (Tracking Branch Created)")
    func switchBranchRemote() async throws {
        let source = URL(string: "https://github.com/ibrahimcetin/PassbankMD.git")!
        let repositoryDirectory = mockDirectory()
        let repository = try await Repository.clone(from: source, to: repositoryDirectory)

        let localBranches = try repository.branch.list(.local)
        #expect(localBranches.count == 1)  // main branch

        // Get the remote branch
        let remoteBranches = try repository.branch.list(.remote)
            .filter({ $0.referenceType == .direct })  // Filter out symbolic branches (origin/HEAD)
        let remoteBranch = remoteBranches[0]

        // Switch to the remote branch
        try repository.switch(to: remoteBranch)

        // Get the HEAD reference
        let head = try repository.HEAD

        let remoteName = try #require(remoteBranch.remote?.name)
        let localBranchName = remoteBranch.name.replacing("\(remoteName)/", with: "")

        // Check the HEAD reference
        #expect(head.name == localBranchName)
        #expect(head.fullName == "refs/heads/\(localBranchName)")
        #expect(head.target.id == remoteBranch.target.id)

        // Check the upstream branch
        let localBranch = try repository.branch.get(named: localBranchName)
        #expect(localBranch.upstream?.name == remoteBranch.name)
        #expect(localBranch.upstream?.fullName == remoteBranch.fullName)
        #expect(localBranch.upstream?.target.id == remoteBranch.target.id)
    }

    @Test("Switch to Commit")
    func switchCommit() throws {
        // Create a new repository at the temporary directory
        let repository = mockRepository()
        let commit = try repository.mockCommit()

        // Switch to the commit
        try repository.switch(to: commit)

        // Get the HEAD reference
        let head = try repository.HEAD

        // Check the HEAD reference (detached HEAD)
        #expect(repository.isHEADDetached)

        #expect(head.name == "HEAD")
        #expect(head.fullName == "HEAD")
    }

    @Test("Switch to Annotated Tag")
    func switchTagAnnotated() throws {
        // Create a new repository at the temporary directory
        let repository = mockRepository()
        let commit = try repository.mockCommit()

        // Create a new tag
        let tag = try repository.tag.create(named: "v1.0.0", target: commit)

        // Switch to the tag
        try repository.switch(to: tag)

        // Get the HEAD reference
        let head = try repository.HEAD

        // Check the HEAD reference
        #expect(head.name == tag.name)
        #expect(head.fullName == tag.fullName)
    }

    @Test("Switch to Lightweight Tag")
    func switchTagLightweight() throws {
        // Create a new repository at the temporary directory
        let repository = mockRepository()
        let commit = try repository.mockCommit()

        // Create a new tag
        let tag = try repository.tag.create(named: "v1.0.0", target: commit, type: .lightweight)

        // When a lightweight tag is created, the tag ID is the same as the commit ID
        #expect(tag.id == commit.id)

        // Switch to the tag
        try repository.switch(to: tag)

        // Get the HEAD reference
        let head = try repository.HEAD

        // Check the HEAD reference
        #expect(head.target.id == tag.id)

        #expect(head.name == tag.name)
        #expect(head.fullName == tag.fullName)
    }

    @Test("Switch to Lightweight Tag Tree Should Fail")
    func switchTagLightweightTreeFailure() throws {
        // Create a new repository at the temporary directory
        let repository = mockRepository()
        let commit = try repository.mockCommit()

        // Create a new tag
        let tag = try repository.tag.create(named: "v1.0.0", target: commit.tree, type: .lightweight)

        // Switch to the tag
        #expect(throws: Error.self) {
            try repository.switch(to: tag)
        }
    }

    // TODO: Add test for remote branch checkout
}
