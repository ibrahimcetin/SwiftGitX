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
    // TODO: Implement options as parameter
    public nonisolated func fetch(remote: Remote? = nil) async throws(SwiftGitXError) {
        guard let remote = remote ?? (try? branch.current.remote) ?? self.remote["origin"] else {
            throw SwiftGitXError(code: .notFound, category: .reference, message: "Remote not found")
        }

        // Lookup the remote
        let remotePointer = try ReferenceFactory.lookupRemotePointer(name: remote.name, repositoryPointer: pointer)
        defer { git_remote_free(remotePointer) }

        // Perform the fetch operation
        try git(operation: .fetch) {
            git_remote_fetch(remotePointer, nil, nil, nil)
        }
    }
}
