//
//  Repository+merge.swift
//  SwiftGitX
//
//  Created by dunkbing
//

import libgit2

extension Repository {
    /// Merges a branch into the current branch.
    ///
    /// - Parameter branch: The branch to merge into HEAD.
    public func merge(branch: Branch) throws(SwiftGitXError) {
        guard let commit = branch.target as? Commit else {
            throw SwiftGitXError(
                code: .error, operation: .merge, category: .reference,
                message: "Branch does not point to a commit"
            )
        }

        var commitOID = commit.id.raw
        var annotatedCommit: OpaquePointer?

        try git(operation: .merge) {
            git_annotated_commit_lookup(&annotatedCommit, pointer, &commitOID)
        }
        defer { git_annotated_commit_free(annotatedCommit) }

        try performMerge(annotatedCommit: annotatedCommit!, branch: branch, commit: commit)
    }

    // MARK: - Internal

    func performMerge(
        annotatedCommit: OpaquePointer,
        branch: Branch,
        commit: Commit
    ) throws(SwiftGitXError) {
        var mergeOptions = git_merge_options()
        git_merge_options_init(&mergeOptions, UInt32(GIT_MERGE_OPTIONS_VERSION))

        var checkoutOptions = git_checkout_options()
        git_checkout_options_init(&checkoutOptions, UInt32(GIT_CHECKOUT_OPTIONS_VERSION))
        checkoutOptions.checkout_strategy = GIT_CHECKOUT_SAFE.rawValue

        var annotatedCommits: [OpaquePointer?] = [annotatedCommit]

        try git(operation: .merge) {
            annotatedCommits.withUnsafeMutableBufferPointer { buffer in
                git_merge(pointer, buffer.baseAddress, 1, &mergeOptions, &checkoutOptions)
            }
        }

        let index = try git(operation: .merge) {
            var indexPointer: OpaquePointer?
            let status = git_repository_index(&indexPointer, pointer)
            return (indexPointer, status)
        }
        defer { git_index_free(index) }

        if git_index_has_conflicts(index) == 1 {
            git_repository_state_cleanup(pointer)
            throw SwiftGitXError(
                code: .conflict, operation: .merge, category: .merge,
                message: "Merge conflicts detected"
            )
        }

        try createMergeCommit(branch: branch, commit: commit)
        git_repository_state_cleanup(pointer)
    }

    private func createMergeCommit(branch: Branch, commit: Commit) throws(SwiftGitXError) {
        let index = try git(operation: .merge) {
            var indexPointer: OpaquePointer?
            let status = git_repository_index(&indexPointer, pointer)
            return (indexPointer, status)
        }
        defer { git_index_free(index) }

        var treeOID = git_oid()
        try git(operation: .merge) {
            git_index_write_tree(&treeOID, index)
        }

        let tree = try git(operation: .merge) {
            var treePointer: OpaquePointer?
            let status = git_tree_lookup(&treePointer, pointer, &treeOID)
            return (treePointer, status)
        }
        defer { git_tree_free(tree) }

        let headCommit = try HEAD.target as! Commit

        var signature: UnsafeMutablePointer<git_signature>?
        try git(operation: .merge) {
            git_signature_default(&signature, pointer)
        }
        defer { git_signature_free(signature) }

        let message = "Merge branch '\(branch.displayName)'"

        let headCommitPointer = try ObjectFactory.lookupObjectPointer(
            oid: headCommit.id.raw,
            type: GIT_OBJECT_COMMIT,
            repositoryPointer: pointer
        )
        defer { git_object_free(headCommitPointer) }

        let remoteCommitPointer = try ObjectFactory.lookupObjectPointer(
            oid: commit.id.raw,
            type: GIT_OBJECT_COMMIT,
            repositoryPointer: pointer
        )
        defer { git_object_free(remoteCommitPointer) }

        var commitOID = git_oid()
        var parents: [OpaquePointer?] = [headCommitPointer, remoteCommitPointer]

        try git(operation: .merge) {
            parents.withUnsafeMutableBufferPointer { buffer in
                git_commit_create(
                    &commitOID,
                    pointer,
                    "HEAD",
                    signature,
                    signature,
                    nil,
                    message,
                    tree,
                    2,
                    buffer.baseAddress
                )
            }
        }
    }
}

extension Branch {
    var displayName: String {
        if type == .remote {
            let remoteName = remote?.name ?? "origin"
            return name.replacingOccurrences(of: "\(remoteName)/", with: "")
        }
        return name
    }
}
