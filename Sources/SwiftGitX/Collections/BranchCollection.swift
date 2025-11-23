import libgit2

public enum BranchCollectionError: Error {
    case failedToList(String)
    case failedToCreate(String)
    case failedToDelete(String)
    case failedToRename(String)
    case failedToGetCurrent(String)
    case failedToSetUpstream(String)
}

/// A collection of branches and their operations.
public struct BranchCollection: Sequence {
    private let repositoryPointer: OpaquePointer

    init(repositoryPointer: OpaquePointer) {
        self.repositoryPointer = repositoryPointer
    }

    // * I am not sure calling `git_error_last()` from a computed property is safe.
    // * Because libgit2 docs say that "The error message is thread-local. The git_error_last() call must happen on the
    // * same thread as the error in order to get the message."
    // * But, I think it is worth a try.
    private var errorMessage: String {
        String(cString: git_error_last().pointee.message)
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
    /// - Throws: `BranchCollectionError.failedToGetCurrent` if the current branch could not be retrieved.
    /// If the repository is in a detached HEAD state, an error will be thrown.
    ///
    /// This is the branch that the repository's HEAD is pointing to.
    public var current: Branch {
        get throws {
            var branchPointer: OpaquePointer?
            defer { git_reference_free(branchPointer) }

            let status = git_repository_head(&branchPointer, repositoryPointer)

            guard let branchPointer, status == GIT_OK.rawValue,
                git_reference_is_branch(branchPointer) == 1
            else { throw BranchCollectionError.failedToGetCurrent(errorMessage) }

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
    public func get(named name: String, type: BranchType = .all) throws -> Branch {
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
    public func list(_ type: BranchType = .all) throws -> [Branch] {
        // Create a branch iterator
        var branchIterator: OpaquePointer?
        defer { git_branch_iterator_free(branchIterator) }

        let status = git_branch_iterator_new(&branchIterator, repositoryPointer, type.raw)

        guard let branchIterator, status == GIT_OK.rawValue else {
            throw BranchCollectionError.failedToList(errorMessage)
        }

        var branches = [Branch]()
        var branchType = type.raw

        while true {
            var branchPointer: OpaquePointer?
            defer { git_reference_free(branchPointer) }

            let nextStatus = git_branch_next(&branchPointer, &branchType, branchIterator)

            if nextStatus == GIT_ITEROVER.rawValue {
                break
            } else if nextStatus != GIT_OK.rawValue {
                throw BranchCollectionError.failedToList(errorMessage)
            } else if let branchPointer {
                // Create a branch
                let branch = try Branch(pointer: branchPointer)
                branches.append(branch)
            } else {
                throw BranchCollectionError.failedToList("Failed to get branch")
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
    public func create(named name: String, target: Commit, force: Bool = false) throws -> Branch {
        // Lookup the target commit
        let targetPointer = try ObjectFactory.lookupObjectPointer(
            oid: target.id.raw,
            type: GIT_OBJECT_COMMIT,
            repositoryPointer: repositoryPointer
        )
        defer { git_object_free(targetPointer) }

        // Create the branch
        var branchPointer: OpaquePointer?
        defer { git_reference_free(branchPointer) }

        let status = git_branch_create(&branchPointer, repositoryPointer, name, targetPointer, force ? 1 : 0)

        guard let branchPointer, status == GIT_OK.rawValue else {
            throw BranchCollectionError.failedToCreate(errorMessage)
        }

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
    ///
    /// - Throws: `BranchCollectionError.failedToCreate` if the branch could not be created.
    @discardableResult
    public func create(named name: String, from fromBranch: Branch, force: Bool = false) throws -> Branch {
        guard fromBranch.type == .local else {
            throw BranchCollectionError.failedToCreate("Branch must be a local branch")
        }

        guard let target = fromBranch.target as? Commit else {
            throw BranchCollectionError.failedToCreate("Failed to get target commit")
        }

        return try create(named: name, target: target, force: force)
    }

    /// Deletes the specified branch.
    ///
    /// - Parameter branch: The branch to be deleted.
    ///
    /// - Throws: `BranchCollectionError.failedToDelete` if the branch could not be deleted.
    public func delete(_ branch: Branch) throws {
        let branchPointer = try ReferenceFactory.lookupBranchPointer(
            name: branch.name,
            type: BranchType.local.raw,
            repositoryPointer: repositoryPointer
        )
        defer { git_reference_free(branchPointer) }

        // Delete the branch
        let deleteStatus = git_branch_delete(branchPointer)

        guard deleteStatus == GIT_OK.rawValue else {
            throw BranchCollectionError.failedToDelete(errorMessage)
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
    public func rename(_ branch: Branch, to newName: String, force: Bool = false) throws -> Branch {
        let branchPointer = try ReferenceFactory.lookupBranchPointer(
            name: branch.name,
            type: BranchType.local.raw,
            repositoryPointer: repositoryPointer
        )
        defer { git_reference_free(branchPointer) }

        // New branch pointer
        var newBranchPointer: OpaquePointer?
        defer { git_reference_free(newBranchPointer) }

        // Rename the branch
        let renameStatus = git_branch_move(&newBranchPointer, branchPointer, newName, force ? 1 : 0)

        guard let newBranchPointer, renameStatus == GIT_OK.rawValue else {
            throw BranchCollectionError.failedToRename(errorMessage)
        }

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
    public func setUpstream(from localBranch: Branch? = nil, to upstreamBranch: Branch?) throws {
        // Get the local branch pointer
        let localBranchPointer = try ReferenceFactory.lookupBranchPointer(
            name: (localBranch ?? current).name,
            type: GIT_BRANCH_LOCAL,
            repositoryPointer: repositoryPointer
        )
        defer { git_reference_free(localBranchPointer) }

        // Set the upstream branch
        let status = git_branch_set_upstream(localBranchPointer, upstreamBranch?.name)

        guard status == GIT_OK.rawValue else {
            throw BranchCollectionError.failedToSetUpstream(errorMessage)
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
