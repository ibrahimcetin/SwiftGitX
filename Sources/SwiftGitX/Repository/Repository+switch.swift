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
    /// - Throws: `RepositoryError.failedToSwitch` if the switch operation fails.
    ///
    /// If the branch does not exist locally, the method tries to find a remote branch with the same name.
    public func `switch`(to branch: Branch) throws {
        // Get the list of local branches. Use list(.local) to throw an error if the operation fails.
        let localBranchExists = try self.branch.list(.local).map(\.fullName).contains(branch.fullName)

        if localBranchExists {
            // Perform the checkout operation
            try checkout(commitID: branch.target.id)

            // Set the HEAD to the reference
            try setHEAD(to: branch)
        } else {
            if let localBranch = try guessBranch(named: branch.name) {
                // Perform the checkout operation
                try checkout(commitID: localBranch.target.id)

                // Set the HEAD to the reference
                try setHEAD(to: localBranch)
            } else {
                throw RepositoryError.failedToSwitch("Failed to checkout the reference")
            }
        }
    }

    /// Switches the HEAD to the specified tag.
    ///
    /// - Parameter tag: The tag to switch to.
    ///
    /// - Throws: `RepositoryError.failedToSwitch` if the switch operation fails.
    ///
    /// The repository will be in a detached HEAD state after switching to the tag.
    public func `switch`(to tag: Tag) throws {
        // Perform the checkout operation
        try checkout(commitID: tag.target.id)

        // Set the HEAD to the tag
        try setHEAD(to: tag)
    }

    /// Switches the HEAD to the specified commit.
    ///
    /// - Parameter commit: The commit to switch to.
    ///
    /// - Throws: `RepositoryError.failedToSwitch` if the switch operation fails.
    ///
    /// The repository will be in a detached HEAD state after switching to the commit.
    public func `switch`(to commit: Commit) throws {
        // Perform the checkout operation
        try checkout(commitID: commit.id)

        // Set the HEAD to the commit
        try setHEAD(to: commit)
    }

    // TODO: Implement checkout options as parameter
    private func checkout(commitID: OID) throws {
        // Lookup the commit
        let commitPointer = try ObjectFactory.lookupObjectPointer(
            oid: commitID.raw,
            type: GIT_OBJECT_COMMIT,
            repositoryPointer: pointer
        )
        defer { git_object_free(commitPointer) }

        var options = git_checkout_options()
        git_checkout_init_options(&options, UInt32(GIT_CHECKOUT_OPTIONS_VERSION))

        options.checkout_strategy = GIT_CHECKOUT_SAFE.rawValue

        // Perform the checkout operation
        let checkoutStatus = git_checkout_tree(pointer, commitPointer, &options)

        guard checkoutStatus == GIT_OK.rawValue else {
            let errorMessage = String(cString: git_error_last().pointee.message)
            throw RepositoryError.failedToSwitch(errorMessage)
        }
    }

    private func setHEAD(to reference: any Reference) throws {
        let status = git_repository_set_head(pointer, reference.fullName)

        guard status == GIT_OK.rawValue else {
            let errorMessage = String(cString: git_error_last().pointee.message)
            throw RepositoryError.failedToSetHEAD(errorMessage)
        }
    }

    private func setHEAD(to commit: Commit) throws {
        var commitID = commit.id.raw
        let status = git_repository_set_head_detached(pointer, &commitID)

        guard status == GIT_OK.rawValue else {
            let errorMessage = String(cString: git_error_last().pointee.message)
            throw RepositoryError.failedToSetHEAD(errorMessage)
        }
    }

    private func guessBranch(named branchName: String) throws -> Branch? {
        // Get the list of remotes
        for remote in try remote.list() {
            // Get the list of remote branches for each remote
            for remoteBranch in remote.branches where remoteBranch.name == branchName {
                // If the tracking branch is found, create a local branch from it
                guard let target = remoteBranch.target as? Commit
                else { continue }

                // Remove the remote name from the branch name
                let newBranchName = remoteBranch.name.replacingOccurrences(of: "\(remote.name)/", with: "")

                // Create a new branch from the remote branch
                return try self.branch.create(named: newBranchName, target: target)
            }
        }

        return nil
    }
}
