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
    public func reset(to commit: Commit, mode resetMode: ResetOption = .soft) throws {
        // Lookup the commit pointer
        let commitPointer = try ObjectFactory.lookupObjectPointer(
            oid: commit.id.raw,
            type: GIT_OBJECT_COMMIT,
            repositoryPointer: pointer
        )
        defer { git_object_free(commitPointer) }

        // TODO: Implement checkout options

        // Perform the reset operation
        let resetStatus = git_reset(pointer, commitPointer, resetMode.raw, nil)

        guard resetStatus == GIT_OK.rawValue else {
            let errorMessage = String(cString: git_error_last().pointee.message)
            throw RepositoryError.failedToReset(errorMessage)
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
    public func reset(from commit: Commit, paths: [String]) throws {
        // Lookup the commit pointer
        let headCommitPointer = try ObjectFactory.lookupObjectPointer(
            oid: commit.id.raw,
            type: GIT_OBJECT_COMMIT,
            repositoryPointer: pointer
        )
        defer { git_object_free(headCommitPointer) }

        // Initialize the checkout options
        let status = paths.withGitStrArray { strArray in
            var strArray = strArray

            // Reset the index from the commit
            return git_reset_default(pointer, headCommitPointer, &strArray)
        }

        guard status == GIT_OK.rawValue else {
            let errorMessage = String(cString: git_error_last().pointee.message)
            throw RepositoryError.failedToReset(errorMessage)
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
    public func reset(from commit: Commit, files: [URL]) throws {
        let paths = try files.map {
            try $0.relativePath(from: workingDirectory)
        }

        try reset(from: commit, paths: paths)
    }
}
