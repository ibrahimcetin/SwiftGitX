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
    /// - Throws: `RepositoryError.failedToCommit` if the commit operation fails.
    ///
    /// This method uses the default author and committer information.
    @discardableResult
    public func commit(message: String, options: CommitOptions = .default) throws -> Commit {
        // Create a new commit from the index
        var oid = git_oid()
        var gitOptions = options.gitCommitCreateOptions

        let status = git_commit_create_from_stage(
            &oid,
            pointer,
            message,
            &gitOptions
        )

        guard status == GIT_OK.rawValue else {
            let errorMessage = String(cString: git_error_last().pointee.message)
            throw RepositoryError.failedToCommit(errorMessage)
        }

        // Lookup the resulting commit
        return try ObjectFactory.lookupObject(oid: oid, repositoryPointer: pointer)
    }
}
