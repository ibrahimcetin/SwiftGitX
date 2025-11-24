//
//  Repository+revert.swift
//  SwiftGitX
//
//  Created by İbrahim Çetin on 23.11.2025.
//

import libgit2

extension Repository {
    /// Reverts the given commit.
    ///
    /// - Parameters:
    ///   - commit: The commit to revert.
    ///
    /// This method reverts the given commit, producing changes in the index and working directory.
    public func revert(_ commit: Commit) throws(SwiftGitXError) {
        // Lookup the commit pointer
        let commitPointer = try ObjectFactory.lookupObjectPointer(
            oid: commit.id.raw,
            type: GIT_OBJECT_COMMIT,
            repositoryPointer: pointer
        )
        defer { git_object_free(commitPointer) }

        // TODO: Implement revert options

        // Perform the revert operation
        try git(operation: .revert) {
            git_revert(pointer, commitPointer, nil)
        }
    }
}
