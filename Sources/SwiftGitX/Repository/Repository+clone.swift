//
//  Repository+clone.swift
//  SwiftGitX
//
//  Created by İbrahim Çetin on 23.11.2025.
//

import Foundation
import libgit2

extension Repository {
    // TODO: Fix blocking async - libgit2 calls block Swift's cooperative threads. Find a way to make it non-blocking.

    /// Clone a repository from the specified URL to the specified path.
    ///
    /// - Parameters:
    ///   - url: The URL of the repository to clone.
    ///   - path: The path to clone the repository to.
    ///
    /// - Returns: The cloned repository at the specified path.
    ///
    /// - Throws: `SwiftGitXError` if the repository cannot be cloned.
    public nonisolated static func clone(
        from remoteURL: URL,
        to localURL: URL,
        options: CloneOptions = .default
    ) async throws(SwiftGitXError) -> Repository {
        // Initialize the clone options
        var options = options.gitCloneOptions

        // Set the checkout strategy
        options.checkout_opts.checkout_strategy = GIT_CHECKOUT_SAFE.rawValue

        // Set the transferProgress callback
        options.fetch_opts.callbacks.transfer_progress = { _, _ in
            // If the task is cancelled, return 1 to stop the transfer. Otherwise, return 0 to continue the transfer.
            Task.isCancelled ? 1 : 0
        }

        let pointer = try git(operation: .clone) {
            // Repository pointer
            var pointer: OpaquePointer?
            // Perform the clone operation
            let status = git_clone(&pointer, remoteURL.absoluteString, localURL.path, &options)

            return (pointer, status)
        }

        return Repository(pointer: pointer)
    }

    /// Clone a repository from the specified URL to the specified path with a transfer progress handler.
    ///
    /// - Parameters:
    ///   - url: The URL of the repository to clone.
    ///   - path: The path to clone the repository to.
    ///   - transferProgressHandler: A closure that is called with the transfer progress.
    ///
    /// - Returns: The cloned repository at the specified path.
    ///
    /// - Throws: `SwiftGitXError` if the repository cannot be cloned.
    public nonisolated static func clone(
        from remoteURL: URL,
        to localURL: URL,
        options: CloneOptions = .default,
        transferProgressHandler: @escaping TransferProgressHandler
    ) async throws(SwiftGitXError) -> Repository {
        // Define the transferProgress callback
        let transferProgress: git_indexer_progress_cb = { stats, payload in
            guard let stats = stats?.pointee,
                let payload = payload?.assumingMemoryBound(to: TransferProgressHandler.self),
                Task.isCancelled == false  // Make sure the task is not cancelled
            else {
                // If the stats, the payload is nil or the task is cancelled, return 1 to stop the transfer
                return 1
            }

            // Create a TransferProgress instance from the stats
            let progress = TransferProgress(from: stats)

            // Get the transferProgressHandler from the payload
            let transferProgressHandler = payload.pointee

            // Call the transferProgressHandler
            transferProgressHandler(progress)

            // Return 0 to continue the transfer
            return 0
        }

        // Initialize the clone options
        var options = options.gitCloneOptions

        // Set the checkout strategy
        options.checkout_opts.checkout_strategy = GIT_CHECKOUT_SAFE.rawValue

        // Set the transferProgress callback
        options.fetch_opts.callbacks.transfer_progress = transferProgress

        // Allocate memory for the transferProgressHandler to pass it to the callback
        let transferProgressHandlerPointer = UnsafeMutablePointer<TransferProgressHandler>.allocate(capacity: 1)
        transferProgressHandlerPointer.initialize(to: transferProgressHandler)
        defer { transferProgressHandlerPointer.deallocate() }

        // Set the transferProgressHandler as the payload
        options.fetch_opts.callbacks.payload = UnsafeMutableRawPointer(transferProgressHandlerPointer)

        // Perform the clone operation
        let pointer = try git(operation: .clone) {
            var pointer: OpaquePointer?
            let status = git_clone(&pointer, remoteURL.absoluteString, localURL.path, &options)
            return (pointer, status)
        }

        return Repository(pointer: pointer)
    }
}
