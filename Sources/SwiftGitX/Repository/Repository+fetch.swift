//
//  Repository+fetch.swift
//  SwiftGitX
//
//  Created by İbrahim Çetin on 23.11.2025.
//

import libgit2

extension Repository {
    /// Fetch the objects and refs from the other repository.
    ///
    /// - Parameter remote: The remote to fetch the changes from.
    ///
    /// This method uses the default refspecs to fetch the changes from the remote.
    ///
    /// If the remote is not specified, the upstream of the current branch is used
    /// and if the upstream branch is not found, the `origin` remote is used.
    public func fetch(remote: Remote? = nil) async throws {
        try await withUnsafeThrowingContinuation { continuation in
            do {
                try fetch(remote: remote)
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private func fetch(remote: Remote? = nil) throws {
        guard let remote = remote ?? (try? branch.current.remote) ?? self.remote["origin"] else {
            throw RepositoryError.failedToFetch("Invalid remote")
        }

        // Lookup the remote
        let remotePointer = try ReferenceFactory.lookupRemotePointer(name: remote.name, repositoryPointer: pointer)
        defer { git_remote_free(remotePointer) }

        // Perform the fetch operation
        let fetchStatus = git_remote_fetch(remotePointer, nil, nil, nil)

        guard fetchStatus == GIT_OK.rawValue else {
            let errorMessage = String(cString: git_error_last().pointee.message)
            throw RepositoryError.failedToFetch(errorMessage)
        }
    }

    // TODO: Implement pull
}
