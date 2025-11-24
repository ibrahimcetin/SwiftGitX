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
    public func restore(_ restoreOptions: RestoreOption = .workingTree, paths: [String] = []) throws(SwiftGitXError) {
        // TODO: Implement source commit option

        // Initialize the checkout options
        let options = CheckoutOptions(
            strategy: [.force, .disablePathSpecMatch],
            paths: paths
        )

        // TODO: find a better way to handle this instead of using a closure
        let status = try options.withGitCheckoutOptions { (gitCheckoutOptions) throws(SwiftGitXError) -> Int32 in
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
                throw SwiftGitXError(code: .error, category: .invalid, message: "Invalid restore options")
            }
        }

        try SwiftGitXError.check(status, operation: .restore)
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
    public func restore(_ restoreOptions: RestoreOption = .workingTree, files: [URL]) throws(SwiftGitXError) {
        let paths = try files.map { (url) throws(SwiftGitXError) -> String in
            try url.relativePath(from: workingDirectory)
        }

        try restore(restoreOptions, paths: paths)
    }
}
