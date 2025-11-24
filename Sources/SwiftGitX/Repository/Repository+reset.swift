//
//  Repository+reset.swift
//  SwiftGitX
//
//  Created by İbrahim Çetin on 23.11.2025.
//

import Foundation
import libgit2

extension Repository {

    // TODO: Implement merge

    // TODO: Implement rebase

    /// Resets the current branch HEAD to the specified commit and optionally modifies index and working tree files.
    ///
    /// - Parameters:
    ///   - commit: The commit to reset to.
    ///   - resetMode: The type of the reset operation. Default is `.soft`.
    ///
    /// Info: To undo the staged files use `restore` method with `.staged` option.
    ///
    /// With specifying `resetType`, you can optionally modify index and working tree files.
    /// The default is `.soft` which does not modify index and working tree files.
    public func reset(to commit: Commit, mode resetMode: ResetOption = .soft) throws(SwiftGitXError) {
        // Lookup the commit pointer
        let commitPointer = try ObjectFactory.lookupObjectPointer(
            oid: commit.id.raw,
            type: GIT_OBJECT_COMMIT,
            repositoryPointer: pointer
        )
        defer { git_object_free(commitPointer) }

        // TODO: Implement checkout options

        // Perform the reset operation
        try git(operation: .reset) {
            git_reset(pointer, commitPointer, resetMode.raw, nil)
        }
    }

    /// Copies entries from a commit to the index.
    ///
    /// - Parameters:
    ///   - commit: The commit to reset from.
    ///   - paths: The paths of the files to reset. Default is an empty array which resets all files.
    ///
    /// This method reset the index entries for all paths that match the `paths` to their
    /// state at `commit`. (It does not affect the working tree or the current branch.)
    ///
    /// This means that this method is the opposite of `add()` method.
    /// This command is equivalent to `restore` method with `.staged` option.
    public func reset(from commit: Commit, paths: [String]) throws(SwiftGitXError) {
        // Lookup the commit pointer
        let headCommitPointer = try ObjectFactory.lookupObjectPointer(
            oid: commit.id.raw,
            type: GIT_OBJECT_COMMIT,
            repositoryPointer: pointer
        )
        defer { git_object_free(headCommitPointer) }

        // Initialize the checkout options
        var strArray = paths.gitStrArray
        defer { git_strarray_free(&strArray) }

        // Reset the index from the commit
        try git(operation: .reset) {
            git_reset_default(pointer, headCommitPointer, &strArray)
        }
    }

    /// Copies entries from a commit to the index.
    ///
    /// - Parameters:
    ///   - commit: The commit to reset from.
    ///   - files: The files of the files to reset. Default is an empty array which resets all files.
    ///
    /// This method reset the index entries for all files that match the `files` to their
    /// state at `commit`. (It does not affect the working tree or the current branch.)
    ///
    /// This means that this method is the opposite of `add()` method.
    /// This command is equivalent to `restore` method with `.staged` option.
    public func reset(from commit: Commit, files: [URL]) throws(SwiftGitXError) {
        let paths = try files.map { (url) throws(SwiftGitXError) -> String in
            try url.relativePath(from: workingDirectory)
        }

        try reset(from: commit, paths: paths)
    }
}
