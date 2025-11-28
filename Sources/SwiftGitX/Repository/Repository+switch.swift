//
//  Repository+switch.swift
//  SwiftGitX
//
//  Created by İbrahim Çetin on 23.11.2025.
//

import libgit2

extension Repository {
    /// Switches the HEAD to the specified branch.
    ///
    /// - Parameter branch: The branch to switch to.
    ///
    /// - Throws: `SwiftGitXError` if the switch operation fails.
    ///
    /// This method updates both the working directory and the HEAD reference to point to the specified branch.
    ///
    /// - For **local branches**: The method checks out the branch and updates HEAD to point to it.
    /// - For **remote branches**: The method creates a local tracking branch (if it doesn't exist),
    ///   sets up upstream tracking, checks out the local branch, and updates HEAD to point to it.
    ///
    /// ### Example
    /// ```swift
    /// // Switch to a local branch
    /// let branch = try repository.branch.get(named: "develop")
    /// try repository.switch(to: branch)
    ///
    /// // Switch to a remote branch (creates local tracking branch)
    /// let remoteBranch = try repository.branch.get(named: "origin/feature", type: .remote)
    /// try repository.switch(to: remoteBranch)
    /// ```
    public func `switch`(to branch: Branch) throws(SwiftGitXError) {
        let localBranch: Branch

        if branch.type == .remote {
            localBranch = try createTrackingBranch(from: branch)
        } else {
            localBranch = branch
        }

        try checkout(to: localBranch)
        try setHEAD(to: localBranch)
    }

    /// Switches the HEAD to the specified tag.
    ///
    /// - Parameter tag: The tag to switch to.
    ///
    /// This method updates both the working directory and the HEAD reference to point to the specified tag.
    ///
    /// ### Example
    /// ```swift
    /// let tag = try repository.tag.get(named: "v1.0.0")
    /// try repository.switch(to: tag)
    /// ```
    public func `switch`(to tag: Tag) throws(SwiftGitXError) {
        try checkout(to: tag)
        try setHEAD(to: tag)
    }

    /// Switches the HEAD to the specified commit.
    ///
    /// - Parameter commit: The commit to switch to.
    ///
    /// This method updates both the working directory and the HEAD reference to point to the specified commit.
    ///
    /// - Note: The repository will be in a detached HEAD state after switching to the commit.
    ///
    /// ### Example
    /// ```swift
    /// let commit = try repository.log().first!
    /// try repository.switch(to: commit)
    /// ```
    public func `switch`(to commit: Commit) throws(SwiftGitXError) {
        try checkout(to: commit)
        try setHEAD(to: commit)
    }

    // MARK: - Private Helpers

    /// Sets HEAD to point to the specified reference (branch or tag).
    private func setHEAD(to reference: any Reference) throws(SwiftGitXError) {
        try git(operation: .switch) {
            git_repository_set_head(pointer, reference.fullName)
        }
    }

    /// Sets HEAD to point directly to the specified commit (detached HEAD).
    private func setHEAD(to commit: Commit) throws(SwiftGitXError) {
        var commitID = commit.id.raw
        try git(operation: .switch) {
            git_repository_set_head_detached(pointer, &commitID)
        }
    }

    /// Creates a local tracking branch from a remote branch.
    ///
    /// - Parameters:
    ///   - remoteBranch: The remote branch to create the local branch from.
    ///
    /// - Returns: The newly created local branch with upstream tracking configured.
    private func createTrackingBranch(from remoteBranch: Branch) throws(SwiftGitXError) -> Branch {
        guard let commit = remoteBranch.target as? Commit else {
            throw SwiftGitXError(
                code: .error, operation: .switch, category: .reference,
                message: "Remote branch does not point to a commit"
            )
        }

        let remoteName = remoteBranch.remote?.name ?? "origin"
        let localBranchName = remoteBranch.name.replacingOccurrences(of: "\(remoteName)/", with: "")

        switch self.branch[localBranchName, type: .local] {
        case .some(let localBranch):
            // If the local branch exists, return it
            if localBranch.upstream?.name != remoteBranch.name {
                try self.branch.setUpstream(from: localBranch, to: remoteBranch)
            }

            return localBranch
        case .none:
            // If the local branch does not exist, continue to create it
            // Create the local branch
            let localBranch = try self.branch.create(named: localBranchName, target: commit)

            // Set up upstream tracking
            try self.branch.setUpstream(from: localBranch, to: remoteBranch)

            // Return fresh branch with upstream info populated
            return try self.branch.get(named: localBranchName, type: .local)
        }

    }
}
