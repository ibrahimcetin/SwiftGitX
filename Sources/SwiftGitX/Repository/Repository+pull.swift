//
//  Repository+pull.swift
//  SwiftGitX
//
//  Created by dunkbing
//

import libgit2

extension Repository {
    /// Pulls changes from remote and integrates them into current branch.
    ///
    /// - Parameters:
    ///   - remote: Remote to pull from (defaults to upstream or origin).
    ///   - option: Pull strategy (default: `.auto`).
    public nonisolated func pull(
        remote: Remote? = nil,
        option: PullOption = .auto
    ) async throws(SwiftGitXError) {
        let currentBranch = try branch.current

        guard let remote = remote ?? currentBranch.remote ?? self.remote["origin"] else {
            throw SwiftGitXError(code: .notFound, operation: .pull, category: .reference, message: "Remote not found")
        }

        guard let upstream = currentBranch.upstream else {
            throw SwiftGitXError(
                code: .notFound, operation: .pull, category: .reference,
                message: "No upstream configured for '\(currentBranch.name)'"
            )
        }

        try await fetch(remote: remote)

        let remoteBranch = try branch.get(named: upstream.name, type: .remote)

        guard let remoteCommit = remoteBranch.target as? Commit else {
            throw SwiftGitXError(
                code: .error, operation: .pull, category: .reference,
                message: "Remote branch does not point to a commit"
            )
        }

        // Analyze merge
        var analysis = git_merge_analysis_t(rawValue: 0)
        var preference = git_merge_preference_t(rawValue: 0)
        var remoteOID = remoteCommit.id.raw
        var annotatedCommit: OpaquePointer?

        try git(operation: .pull) {
            git_annotated_commit_lookup(&annotatedCommit, pointer, &remoteOID)
        }
        defer { git_annotated_commit_free(annotatedCommit) }

        var annotatedCommits: [OpaquePointer?] = [annotatedCommit]

        try git(operation: .pull) {
            annotatedCommits.withUnsafeMutableBufferPointer { buffer in
                git_merge_analysis(&analysis, &preference, pointer, buffer.baseAddress, 1)
            }
        }

        // Already up to date
        if analysis.rawValue & GIT_MERGE_ANALYSIS_UP_TO_DATE.rawValue != 0 {
            return
        }

        let canFastForward = analysis.rawValue & GIT_MERGE_ANALYSIS_FASTFORWARD.rawValue != 0
        let canMerge = analysis.rawValue & GIT_MERGE_ANALYSIS_NORMAL.rawValue != 0

        switch option {
        case .auto:
            if canFastForward {
                try reset(to: remoteCommit, mode: .hard)
            } else if canMerge {
                try merge(branch: remoteBranch)
            } else {
                throw SwiftGitXError(code: .error, operation: .pull, category: .merge, message: "Cannot merge")
            }

        case .fastForwardOnly:
            if canFastForward {
                try reset(to: remoteCommit, mode: .hard)
            } else {
                throw SwiftGitXError(
                    code: .error, operation: .pull, category: .merge,
                    message: "Cannot fast-forward, merge required"
                )
            }

        case .noFastForward:
            if canFastForward || canMerge {
                try merge(branch: remoteBranch)
            } else {
                throw SwiftGitXError(code: .error, operation: .pull, category: .merge, message: "Cannot merge")
            }

        case .rebase:
            try performRebase(onto: remoteCommit)
        }
    }

    // MARK: - Private

    private func performRebase(onto: Commit) throws(SwiftGitXError) {
        var ontoOID = onto.id.raw
        var ontoAnnotated: OpaquePointer?

        try git(operation: .pull) {
            git_annotated_commit_lookup(&ontoAnnotated, pointer, &ontoOID)
        }
        defer { git_annotated_commit_free(ontoAnnotated) }

        var rebase: OpaquePointer?
        try git(operation: .pull) {
            git_rebase_init(&rebase, pointer, nil, nil, ontoAnnotated, nil)
        }
        defer { git_rebase_free(rebase) }

        var signature: UnsafeMutablePointer<git_signature>?
        try git(operation: .pull) {
            git_signature_default(&signature, pointer)
        }
        defer { git_signature_free(signature) }

        while true {
            var operation: UnsafeMutablePointer<git_rebase_operation>?
            let nextStatus = git_rebase_next(&operation, rebase)

            if nextStatus == GIT_ITEROVER.rawValue {
                break
            }

            if nextStatus < 0 {
                git_rebase_abort(rebase)
                throw SwiftGitXError(
                    code: .conflict, operation: .pull, category: .merge,
                    message: "Rebase conflict detected"
                )
            }

            var commitOID = git_oid()
            let commitStatus = git_rebase_commit(&commitOID, rebase, nil, signature, nil, nil)

            if commitStatus < 0 && commitStatus != GIT_EAPPLIED.rawValue {
                git_rebase_abort(rebase)
                throw SwiftGitXError(
                    code: .error, operation: .pull, category: .merge,
                    message: "Failed to commit rebase operation"
                )
            }
        }

        try git(operation: .pull) {
            git_rebase_finish(rebase, signature)
        }
    }
}
