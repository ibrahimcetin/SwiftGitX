//
//  BranchCollection.swift
//  SwiftGitX
//
//  Created by İbrahim Çetin on 24.11.2025.
//

import libgit2

/// A collection of branches and their operations.
public struct BranchCollection: Sequence, Sendable {
    nonisolated(unsafe) private let repositoryPointer: OpaquePointer

    init(repositoryPointer: OpaquePointer) {
        self.repositoryPointer = repositoryPointer
    }

    /// The local branches in the repository.
    public var local: BranchSequence {
        BranchSequence(type: .local, repositoryPointer: repositoryPointer)
    }

    /// The remote branches in the repository.
    public var remote: BranchSequence {
        BranchSequence(type: .remote, repositoryPointer: repositoryPointer)
    }

    /// The current branch.
    ///
    /// - Returns: The current branch.
    ///
    /// If the repository is in a detached HEAD state, an error will be thrown.
    ///
    /// This is the branch that the repository's HEAD is pointing to.
    public var current: Branch {
        get throws(SwiftGitXError) {
            let branchPointer = try git(operation: .head) {
                var branchPointer: OpaquePointer?
                let status = git_repository_head(&branchPointer, repositoryPointer)
                return (branchPointer, status)
            }
            defer { git_reference_free(branchPointer) }

            guard git_reference_is_branch(branchPointer) == 1
            else {
                throw SwiftGitXError(
                    code: .error, category: .reference,
                    message: "HEAD is not a branch. It may be in a detached HEAD state."
                )
            }

            return try Branch(pointer: branchPointer)
        }
    }

    /// Retrieves a branch by its name.
    ///
    /// - Parameter name: The name of the branch.
    ///
    /// - Returns: The branch with the specified name, or `nil` if it doesn't exist.
    public subscript(name: String, type branchType: BranchType = .all) -> Branch? {
        try? get(named: name, type: branchType)
    }

    /// Returns a branch by name.
    ///
    /// - Parameter name: The name of the branch.
    /// For example, `main` for a local branch and `origin/main` for a remote branch.
    ///
    /// - Returns: The branch with the specified name.
    public func get(named name: String, type: BranchType = .all) throws(SwiftGitXError) -> Branch {
        let branchPointer = try ReferenceFactory.lookupBranchPointer(
            name: name,
            type: type.raw,
            repositoryPointer: repositoryPointer
        )
        defer { git_reference_free(branchPointer) }

        return try Branch(pointer: branchPointer)
    }

    /// Returns a list of branches.
    ///
    /// - Parameter type: The type of branches to list. Default is `.all`.
    ///
    /// - Returns: An array of branches.
    public func list(_ type: BranchType = .all) throws(SwiftGitXError) -> [Branch] {
        // Create a branch iterator
        let branchIterator = try git(operation: .branchList) {
            var branchIterator: OpaquePointer?
            let status = git_branch_iterator_new(&branchIterator, repositoryPointer, type.raw)
            return (branchIterator, status)
        }
        defer { git_branch_iterator_free(branchIterator) }

        var branches = [Branch]()
        var branchType = type.raw

        while true {
            do {
                let branchPointer = try git(operation: .branchList) {
                    var branchPointer: OpaquePointer?
                    let status = git_branch_next(&branchPointer, &branchType, branchIterator)
                    return (branchPointer, status)
                }
                defer { git_reference_free(branchPointer) }

                let branch = try Branch(pointer: branchPointer)
                branches.append(branch)
            } catch  where error.code == .iterOver {
                break
            } catch {
                throw error
            }
        }

        return branches
    }

    /// Creates a new branch with the specified name and target commit.
    ///
    /// - Parameters:
    ///   - name: The name of the branch to create.
    ///   - target: The target commit that the branch will point to.
    ///   - force: If `true`, the branch will be overwritten if it already exists. Default is `false`.
    ///
    /// - Returns: The newly created `Branch` object.
    ///
    /// - Throws: `BranchCollectionError.failedToCreate` if the branch could not be created.
    @discardableResult
    public func create(named name: String, target: Commit, force: Bool = false) throws(SwiftGitXError) -> Branch {
        // Lookup the target commit
        let targetPointer = try ObjectFactory.lookupObjectPointer(
            oid: target.id.raw,
            type: GIT_OBJECT_COMMIT,
            repositoryPointer: repositoryPointer
        )
        defer { git_object_free(targetPointer) }

        // Create the branch
        let branchPointer = try git(operation: .branchCreate) {
            var branchPointer: OpaquePointer?
            let status = git_branch_create(&branchPointer, repositoryPointer, name, targetPointer, force ? 1 : 0)
            return (branchPointer, status)
        }
        defer { git_reference_free(branchPointer) }

        return try Branch(pointer: branchPointer)
    }

    /// Creates a new branch with the specified name and target branch.
    ///
    /// - Parameters:
    ///   - name: The name of the branch to create.
    ///   - fromBranch: The branch to create the new branch from.
    ///   - force: If `true`, the branch will be overwritten if it already exists. Default is `false`.
    ///
    /// - Returns: The newly created `Branch` object.
    @discardableResult
    public func create(
        named name: String,
        from fromBranch: Branch,
        force: Bool = false
    ) throws(SwiftGitXError) -> Branch {
        guard fromBranch.type == .local else {
            throw SwiftGitXError(code: .invalid, category: .reference, message: "Branch must be a local branch")
        }

        guard let target = fromBranch.target as? Commit else {
            throw SwiftGitXError(code: .invalid, category: .reference, message: "Branch target is not a commit")
        }

        return try create(named: name, target: target, force: force)
    }

    /// Deletes the specified branch.
    ///
    /// - Parameter branch: The branch to be deleted.
    ///
    /// - Throws: `BranchCollectionError.failedToDelete` if the branch could not be deleted.
    public func delete(_ branch: Branch) throws(SwiftGitXError) {
        let branchPointer = try ReferenceFactory.lookupBranchPointer(
            name: branch.name,
            type: BranchType.local.raw,
            repositoryPointer: repositoryPointer
        )
        defer { git_reference_free(branchPointer) }

        // Delete the branch
        try git(operation: .branchDelete) {
            git_branch_delete(branchPointer)
        }
    }

    /// Renames a branch to a new name.
    ///
    /// - Parameters:
    ///   - branch: The branch to be renamed.
    ///   - newName: The new name for the branch.
    ///   - force: If `true`, the branch will be overwritten if it already exists. Default is `false`.
    ///
    /// - Returns: The renamed branch.
    ///
    /// - Throws: `BranchCollectionError.failedToRename` if the branch could not be renamed.
    @discardableResult
    public func rename(_ branch: Branch, to newName: String, force: Bool = false) throws(SwiftGitXError) -> Branch {
        let branchPointer = try ReferenceFactory.lookupBranchPointer(
            name: branch.name,
            type: BranchType.local.raw,
            repositoryPointer: repositoryPointer
        )
        defer { git_reference_free(branchPointer) }

        // New branch pointer
        let newBranchPointer = try git(operation: .branchRename) {
            var newBranchPointer: OpaquePointer?
            let status = git_branch_move(&newBranchPointer, branchPointer, newName, force ? 1 : 0)
            return (newBranchPointer, status)
        }
        defer { git_reference_free(newBranchPointer) }

        return try Branch(pointer: newBranchPointer)
    }

    /// Set the upstream branch of the specified local branch.
    ///
    /// - Parameters:
    ///   - localBranch: The local branch to set the upstream branch to. Default is the current branch.
    ///   - upstreamBranch: The upstream branch to set.
    ///
    /// - Throws: `BranchCollectionError.failedToSetUpstream` if the upstream branch could not be set.
    ///
    /// If the `localBranch` is not specified, the current branch will be used.
    ///
    /// If the `upstreamBranch` is specified `nil`, the upstream branch will be unset.
    public func setUpstream(from localBranch: Branch? = nil, to upstreamBranch: Branch?) throws(SwiftGitXError) {
        // Get the local branch pointer
        let resolvedLocalBranch: Branch
        if let localBranch {
            resolvedLocalBranch = localBranch
        } else {
            resolvedLocalBranch = try current
        }

        let localBranchPointer = try ReferenceFactory.lookupBranchPointer(
            name: resolvedLocalBranch.name,
            type: GIT_BRANCH_LOCAL,
            repositoryPointer: repositoryPointer
        )
        defer { git_reference_free(localBranchPointer) }

        // Set the upstream branch
        try git(operation: .branchSetUpstream) {
            git_branch_set_upstream(localBranchPointer, upstreamBranch?.name)
        }
    }

    /// An iterator of all branches in the repository.
    ///
    /// - Returns: A iterator of all branches.
    ///
    /// If you want to iterate over local or remote branches, use the `local` or `remote` properties.
    ///
    /// To iterate over all branches in the repository, use the following code:
    /// ```swift
    ///     let branches = repository.branches.all
    ///     for branch in branches {
    ///         print(branch.name)
    ///     }
    /// ```
    ///
    public func makeIterator() -> BranchIterator {
        BranchIterator(type: .all, repositoryPointer: repositoryPointer)
    }
}

extension SwiftGitXError.Operation {
    public static let branchCreate = Self(rawValue: "branchCreate")
    public static let branchDelete = Self(rawValue: "branchDelete")
    public static let branchRename = Self(rawValue: "branchRename")
    public static let branchSetUpstream = Self(rawValue: "branchSetUpstream")
    public static let branchList = Self(rawValue: "branchList")
}
