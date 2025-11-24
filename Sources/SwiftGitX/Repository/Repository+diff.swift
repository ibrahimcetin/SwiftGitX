//
//  Repository+diff.swift
//  SwiftGitX
//
//  Created by İbrahim Çetin on 23.11.2025.
//

import libgit2

extension Repository {
    /// Creates a diff of current changes in the repository.
    ///
    /// - Returns: The diff of the current changes.
    ///
    /// The `from` side is used as `old file` and the `to` side is used as `new file`.
    ///
    /// The default behavior is the same as `git diff`.
    /// If there are staged changes of the file, it create diff from index to working tree.
    /// If there are no staged changes, it create diff from HEAD to working tree.
    ///
    /// If you want to create diff from HEAD to index, you can use `diff(to: .index)`.
    /// This is the same as `git diff --cached`. ``DiffOption/index`` option only gets
    /// differences between HEAD and index.
    ///
    /// The behavior of `git diff HEAD` can be achieved by using `diff(to: [.workingTree, .staged])`.
    /// With this options, it creates diff from HEAD to index and index to working tree and combines them.
    public func diff(to diffOption: DiffOption = .workingTree) throws(SwiftGitXError) -> Diff {
        // TODO: Implement diff options and source commit as parameter

        // Get the HEAD commit
        let headCommit = (try? HEAD.target) as? Commit

        // Get the HEAD commit tree
        let headTreePointer: OpaquePointer? =
            if let headCommit {
                try ObjectFactory.lookupObjectPointer(
                    oid: headCommit.tree.id.raw,
                    type: GIT_OBJECT_TREE,
                    repositoryPointer: pointer
                )
            } else { nil }
        defer { git_object_free(headTreePointer) }

        // Get the diff object
        var diffPointer: OpaquePointer?
        defer { git_diff_free(diffPointer) }

        let diffStatus: Int32 =
            switch diffOption {
            case .workingTree:
                git_diff_index_to_workdir(&diffPointer, pointer, nil, nil)
            case .index:
                git_diff_tree_to_index(&diffPointer, pointer, headTreePointer, nil, nil)
            case [.workingTree, .index]:
                git_diff_tree_to_workdir_with_index(&diffPointer, pointer, headTreePointer, nil)
            default:
                throw SwiftGitXError(code: .error, category: .invalid, message: "Invalid diff option")
            }

        let validDiffPointer = try SwiftGitXError.check(diffStatus, pointer: diffPointer, operation: .diff)

        return Diff(pointer: validDiffPointer)
    }

    /// Get the diff between given commit and its parent.
    ///
    /// - Parameter commit: The commit to get the diff.
    ///
    /// - Returns: The diff between the commit and its parent.
    ///
    /// - Throws: `RepositoryError.failedToGetDiff` if the diff operation fails.
    public func diff(commit: Commit) throws(SwiftGitXError) -> Diff {
        let parents = try commit.parents

        return if parents.isEmpty {
            try diff(from: commit, to: commit)
        } else {
            // TODO: User should be able to specify the parent index
            try diff(from: parents[0], to: commit)
        }
    }

    /// Get the diff between two objects.
    ///
    /// - Parameters:
    ///   - fromObject: The object to compare from.
    ///   - toObject: The object to compare to.
    ///
    /// - Returns: The diff between the two objects.
    ///
    /// - Throws: `RepositoryError.failedToGetDiff` if the diff operation fails.
    ///
    /// - Warning: The objects should be commit, tree, or tag objects.
    /// Blob objects are not supported.
    public func diff(from fromObject: any Object, to toObject: any Object) throws(SwiftGitXError) -> Diff {
        // TODO: Implement diff options

        // Get the tree pointers
        let fromObjectTreePointer = try ObjectFactory.peelObjectPointer(
            oid: fromObject.id.raw,
            targetType: GIT_OBJECT_TREE,
            repositoryPointer: pointer
        )
        defer { git_object_free(fromObjectTreePointer) }

        let toObjectTreePointer = try ObjectFactory.peelObjectPointer(
            oid: toObject.id.raw,
            targetType: GIT_OBJECT_TREE,
            repositoryPointer: pointer
        )
        defer { git_object_free(toObjectTreePointer) }

        // Get the diff object
        let diffPointer = try git {
            var diffPointer: OpaquePointer?
            let status = git_diff_tree_to_tree(
                &diffPointer,
                pointer,
                fromObjectTreePointer,
                toObjectTreePointer,
                nil
            )
            return (diffPointer, status)
        }
        defer { git_diff_free(diffPointer) }

        return Diff(pointer: diffPointer)
    }
}
