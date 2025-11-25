//
//  Repository+commit.swift
//  SwiftGitX
//
//  Created by İbrahim Çetin on 23.11.2025.
//

import libgit2

extension Repository {
    /// Create a new commit containing the current contents of the index.
    ///
    /// - Parameters:
    ///   - message: The commit message.
    ///   - options: The options to use when creating the commit.
    ///
    /// - Returns: The created commit.
    ///
    /// This method uses the default author and committer information.
    @discardableResult
    public func commit(message: String, options: CommitOptions = .default) throws(SwiftGitXError) -> Commit {
        // Create a new commit from the index
        var oid = git_oid()
        var gitOptions = options.gitCommitCreateOptions

        try git(operation: .commit) {
            git_commit_create_from_stage(
                &oid,
                pointer,
                message,
                &gitOptions
            )
        }

        // Lookup the resulting commit
        return try ObjectFactory.lookupCommit(oid: oid, repositoryPointer: pointer)
    }
}
