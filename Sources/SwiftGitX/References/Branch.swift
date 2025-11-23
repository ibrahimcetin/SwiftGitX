import libgit2

public enum BranchError: Error {
    case invalid(String)
}

/// A branch representation in the repository.
public struct Branch: Reference {
    /// The target of the branch.
    public let target: any Object

    // ? Should we add `commit` property to get directly the commit object?

    /// The name of the branch.
    ///
    /// For example, `main` for a local branch and `origin/main` for a remote branch.
    public let name: String

    /// The full name of the branch.
    ///
    /// For example, `refs/heads/main` for a local branch and `refs/remotes/origin/main` for a remote branch.
    public let fullName: String

    /// The type of the branch.
    ///
    /// It can be either `local` or `remote`.
    public let type: BranchType

    /// The upstream branch of the branch.
    ///
    /// This property available for local branches only.
    public let upstream: (any Reference)?

    /// The upstream remote of the branch.
    ///
    /// This property available for both local and remote branches.
    public let remote: Remote?

    init(pointer: OpaquePointer) throws {
        let targetID = git_reference_target(pointer)
        let fullName = git_reference_name(pointer)
        let name = git_reference_shorthand(pointer)

        let repositoryPointer = git_reference_owner(pointer)

        guard let targetID = targetID?.pointee, let fullName, let name, let repositoryPointer else {
            let errorMessage = String(cString: git_error_last().pointee.message)
            throw BranchError.invalid(errorMessage)
        }

        // Get the target object of the branch.
        target = try ObjectFactory.lookupObject(oid: targetID, repositoryPointer: repositoryPointer)

        // Set the name of the branch.
        self.name = String(cString: name)
        self.fullName = String(cString: fullName)

        // Set the type of the branch.
        type =
            if self.fullName.hasPrefix(GitDirectoryConstants.heads) {
                .local
            } else if self.fullName.hasPrefix(GitDirectoryConstants.remotes) {
                .remote
            } else if self.fullName == "HEAD" {
                .local
            } else {
                // ? Should we throw an error here?
                throw BranchError.invalid("Invalid branch type")
            }

        // Get the upstream branch of the branch.
        var upstreamPointer: OpaquePointer?
        defer { git_reference_free(upstreamPointer) }

        let upstreamStatus = git_branch_upstream(&upstreamPointer, pointer)

        upstream =
            if let upstreamPointer, upstreamStatus == GIT_OK.rawValue {
                try Branch(pointer: upstreamPointer)
            } else { nil }

        // Get the remote of the branch.
        var remoteName = git_buf()
        defer { git_buf_free(&remoteName) }

        let remoteNameStatus =
            if type == .local {
                git_branch_upstream_remote(&remoteName, repositoryPointer, fullName)
            } else {
                git_branch_remote_name(&remoteName, repositoryPointer, fullName)
            }

        if let rawRemoteName = remoteName.ptr, remoteNameStatus == GIT_OK.rawValue {
            // Look up the remote.
            var remotePointer: OpaquePointer?
            defer { git_remote_free(remotePointer) }

            let remoteStatus = git_remote_lookup(&remotePointer, repositoryPointer, rawRemoteName)

            remote =
                if let remotePointer, remoteStatus == GIT_OK.rawValue {
                    try Remote(pointer: remotePointer)
                } else { nil }
        } else {
            remote = nil
        }
    }
}
