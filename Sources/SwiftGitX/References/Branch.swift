//
//  Branch.swift
//  SwiftGitX
//
//  Created by İbrahim Çetin on 24.11.2025.
//

import libgit2

/// A branch representation in the repository.
public struct Branch: Reference, Sendable {
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

    /// The type of the reference.
    ///
    /// It can be either `direct` or `symbolic` for branches.
    public let referenceType: ReferenceType

    /// The upstream branch of the branch.
    ///
    /// This property available for local branches only.
    public let upstream: (any Reference)?

    /// The upstream remote of the branch.
    ///
    /// This property available for both local and remote branches.
    public let remote: Remote?

    init(pointer: OpaquePointer) throws(SwiftGitXError) {
        let fullName = git_reference_name(pointer)
        let name = git_reference_shorthand(pointer)

        let repositoryPointer = git_reference_owner(pointer)

        guard let fullName, let name, let repositoryPointer else {
            throw SwiftGitXError(code: .error, category: .reference, message: "Invalid branch")
        }

        let targetID = try git {
            var oid = git_oid()
            let status = git_reference_name_to_id(&oid, repositoryPointer, fullName)
            return (oid, status)
        }

        // Get the target object of the branch.
        target = try ObjectFactory.lookupObject(oid: targetID, repositoryPointer: repositoryPointer)

        // Set the name of the branch.
        self.name = String(cString: name)
        self.fullName = String(cString: fullName)

        // Set the type of the branch.
        self.type =
            if git_reference_is_branch(pointer) == 1 {
                .local
            } else if git_reference_is_remote(pointer) == 1 {
                .remote
            } else {
                .local  // Default to .local if unknown or HEAD
            }

        // Set the type of the reference.
        let referenceType = git_reference_type(pointer)

        switch referenceType {
        case GIT_REFERENCE_DIRECT:
            self.referenceType = .direct
        case GIT_REFERENCE_SYMBOLIC:
            let symbolicTarget = git_reference_symbolic_target(pointer)
            guard let symbolicTarget else {
                throw SwiftGitXError(code: .error, category: .reference, message: "Symbolic branch has no target")
            }
            self.referenceType = .symbolic(target: String(cString: symbolicTarget))
        default:
            self.referenceType = .invalid
        }

        // Get the upstream branch of the branch.
        let upstreamPointer = try? git {
            var upstreamPointer: OpaquePointer?
            let status = git_branch_upstream(&upstreamPointer, pointer)
            return (upstreamPointer, status)
        }
        defer { git_reference_free(upstreamPointer) }

        upstream =
            if let upstreamPointer {
                try Branch(pointer: upstreamPointer)
            } else { nil }

        // Get the remote of the branch.
        var remoteName = git_buf()
        defer { git_buf_free(&remoteName) }

        try? git { [type] in
            if type == .local {
                git_branch_upstream_remote(&remoteName, repositoryPointer, fullName)
            } else {
                git_branch_remote_name(&remoteName, repositoryPointer, fullName)
            }
        }

        if let rawRemoteName = remoteName.ptr, remoteName.size > 0 {
            // Look up the remote.
            let remotePointer = try git {
                var remotePointer: OpaquePointer?
                let remoteStatus = git_remote_lookup(&remotePointer, repositoryPointer, rawRemoteName)
                return (remotePointer, remoteStatus)
            }
            defer { git_remote_free(remotePointer) }

            remote = try Remote(pointer: remotePointer)
        } else {
            remote = nil
        }
    }
}
