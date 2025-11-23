//
//  Repository+restore.swift
//  SwiftGitX
//
//  Created by İbrahim Çetin on 23.11.2025.
//

import Foundation
import libgit2

extension Repository {
    /// Restores working tree files.
    ///
    /// - Parameters:
    ///   - restoreOptions: The restore options. Default is `.workingTree`.
    ///   - paths: The paths of the files to restore. Default is an empty array which restores all files.
    ///
    /// This method restores the working tree files to their state at the HEAD commit.
    ///
    /// This method can also restore the staged files to their state at the HEAD commit.
    public func restore(_ restoreOptions: RestoreOption = .workingTree, paths: [String] = []) throws {
        // TODO: Implement source commit option

        // Initialize the checkout options
        let options = CheckoutOptions(
            strategy: [.force, .disablePathSpecMatch],
            paths: paths
        )

        let status = try options.withGitCheckoutOptions { gitCheckoutOptions in
            var gitCheckoutOptions = gitCheckoutOptions

            switch restoreOptions {
            // https://stackoverflow.com/questions/58003030/
            case .workingTree, []:
                return git_checkout_index(pointer, nil, &gitCheckoutOptions)
            case .staged:
                // https://github.com/libgit2/libgit2/issues/3632
                let headCommitPointer = try ObjectFactory.lookupObjectPointer(
                    oid: HEAD.target.id.raw,
                    type: GIT_OBJECT_COMMIT,
                    repositoryPointer: pointer
                )
                defer { git_object_free(headCommitPointer) }

                // Reset the index to HEAD
                return git_reset_default(pointer, headCommitPointer, &gitCheckoutOptions.paths)
            case [.workingTree, .staged]:
                // Checkout HEAD if source is nil
                return git_checkout_tree(pointer, nil, &gitCheckoutOptions)
            default:
                throw RepositoryError.failedToRestore("Invalid restore options")
            }
        }

        guard status == GIT_OK.rawValue else {
            let errorMessage = String(cString: git_error_last().pointee.message)
            throw RepositoryError.failedToRestore(errorMessage)
        }
    }

    /// Restores working tree files.
    ///
    /// - Parameters:
    ///   - restoreOptions: The restore options. Default is `.workingTree`.
    ///   - files: The files to restore. Default is an empty array which restores all files.
    ///
    /// This method restores the working tree files to their state at the HEAD commit.
    ///
    /// This method can also restore the staged files to their state at the HEAD commit.
    public func restore(_ restoreOptions: RestoreOption = .workingTree, files: [URL]) throws {
        let paths = try files.map {
            try $0.relativePath(from: workingDirectory)
        }

        try restore(restoreOptions, paths: paths)
    }
}
