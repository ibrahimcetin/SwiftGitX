//
//  Repository+push.swift
//  SwiftGitX
//
//  Created by İbrahim Çetin on 23.11.2025.
//

import libgit2

extension Repository {
    /// Push changes of the current branch to the remote.
    ///
    /// - Parameter remote: The remote to push the changes to.
    ///
    /// This method uses the default refspecs to push the changes to the remote.
    ///
    /// If the remote is not specified, the upstream of the current branch is used
    /// and if the upstream branch is not found, the `origin` remote is used.
    public func push(remote: Remote? = nil) async throws {
        try await withUnsafeThrowingContinuation { continuation in
            do {
                try push(remote: remote)
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // TODO: Implement options of these methods

    private func push(remote: Remote? = nil) throws {
        guard let remote = remote ?? (try? branch.current.remote) ?? self.remote["origin"] else {
            throw RepositoryError.failedToPush("Invalid remote")
        }

        // Lookup the remote
        let remotePointer = try ReferenceFactory.lookupRemotePointer(name: remote.name, repositoryPointer: pointer)
        defer { git_remote_free(remotePointer) }

        // Configure the refspecs with the current branch's full name
        var refspecs: git_strarray = try [branch.current.fullName].gitStrArray
        defer { git_strarray_free(&refspecs) }

        // Perform the push operation
        let pushStatus = git_remote_push(remotePointer, &refspecs, nil)

        guard pushStatus == GIT_OK.rawValue else {
            let errorMessage = String(cString: git_error_last().pointee.message)
            throw RepositoryError.failedToPush(errorMessage)
        }
    }
}
