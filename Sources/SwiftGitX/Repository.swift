//
//  Repository.swift
//  SwiftGitX
//
//  Created by İbrahim Çetin on 10.03.2024.
//

import Foundation
import libgit2

/// An enumeration that represents the possible errors that can occur in a repository.
public enum RepositoryError: Error {
    case failedToCreate(String)
    case failedToClone(String)
    case failedToOpen(String)

    case failedToGetWorkingDirectory
    case unbornHEAD

    case failedToCommit(String)
    case failedToReset(String)
    case failedToRevert(String)
    case failedToRestore(String)

    case failedToGetHEAD(String)
    case failedToSetHEAD(String)

    case failedToSwitch(String)

    case failedToGetStatus(String)
    case failedToGetDiff(String)

    case failedToPush(String)
    case failedToFetch(String)
    // case failedToPull(String)
}

// MARK: - Repository

/// A representation of a Git repository.
public class Repository {
    /// The libgit2 pointer of the repository.
    private let pointer: OpaquePointer

    /// Initialize a new repository with the specified libgit2 pointer.
    private init(pointer: OpaquePointer) {
        self.pointer = pointer
    }

    /// Initialize a new repository at the specified path.
    ///
    /// If a repository exists at the specified path, it will be opened.
    /// If a repository does not exist, a new one will be created.
    ///
    /// - Parameter path: The path to the repository.
    ///
    /// - Throws: `RepositoryError.failedToCreate` if the repository cannot be created.
    public init(at path: URL) throws {
        var pointer: OpaquePointer?

        // Try to open the repository at the specified path
        let statusOpen = git_repository_open(&pointer, path.path)

        if let pointer, statusOpen == GIT_OK.rawValue {
            self.pointer = pointer
        } else {
            // If the repository does not exist, create a new one
            let statusCreate = git_repository_init(&pointer, path.path, 0)

            guard let pointer, statusCreate == GIT_OK.rawValue else {
                let errorMessage = String(cString: git_error_last().pointee.message)
                throw RepositoryError.failedToCreate(errorMessage)
            }

            self.pointer = pointer
        }
    }

    deinit {
        git_repository_free(pointer)
    }
}

// MARK: - Repository properties

public extension Repository {
    /// The working directory of the repository.
    ///
    /// - Returns: The URL of the working directory.
    ///
    /// - Throws: `RepositoryError.failedToGetWorkingDirectory` if the repository is bare.
    var workingDirectory: URL {
        get throws {
            guard let path = git_repository_workdir(pointer)
            else { throw RepositoryError.failedToGetWorkingDirectory }

            return URL(fileURLWithPath: String(cString: path), isDirectory: true, relativeTo: nil)
        }
    }

    /// Check if the repository is empty.
    ///
    /// A repository is considered empty if it has no commits.
    var isEmpty: Bool {
        // TODO: Throw an error if the return value is not 0 or 1
        git_repository_is_empty(pointer) == 1
    }

    /// Check if the repository is HEAD detached.
    ///
    /// A repository’s HEAD is detached when it points directly to a commit instead of a branch.
    var isHEADDetached: Bool {
        git_repository_head_detached(pointer) == 1
    }

    /// Check if the repository is HEAD unborn.
    ///
    /// A repository is considered HEAD unborn if the HEAD reference is not yet initialized.
    var isHEADUnborn: Bool {
        git_repository_head_unborn(pointer) == 1
    }

    /// Check if the repository is shallow.
    ///
    /// A repository is considered shallow if it has a limited history.
    var isShallow: Bool {
        git_repository_is_shallow(pointer) == 1
    }

    /// Check if the repository is bare.
    var isBare: Bool {
        git_repository_is_bare(pointer) == 1
    }
}

// MARK: - Repository factory methods

public extension Repository {
    /// Open a repository at the specified path.
    ///
    /// - Parameter path: The path to the repository.
    ///
    /// - Returns: The repository at the specified path.
    ///
    /// - Throws: `RepositoryError.failedToOpen` if the repository cannot be opened.
    static func open(at path: URL) throws -> Repository {
        var pointer: OpaquePointer?
        let status = git_repository_open(&pointer, path.path)

        guard let pointer, status == GIT_OK.rawValue else {
            let errorMessage = String(cString: git_error_last().pointee.message)
            throw RepositoryError.failedToOpen(errorMessage)
        }

        return Repository(pointer: pointer)
    }

    /// Create a new repository at the specified path.
    ///
    /// - Parameters:
    ///   - path: The path to the repository.
    ///   - isBare: A boolean value that indicates whether the repository should be bare.
    ///
    /// - Returns: The repository at the specified path.
    ///
    /// - Throws: `RepositoryError.failedToCreate` if the repository cannot be created.
    static func create(at path: URL, isBare: Bool = false) throws -> Repository {
        // Create a new repository at the specified URL
        var pointer: OpaquePointer?
        let status = git_repository_init(&pointer, path.path, isBare ? 1 : 0)

        guard let pointer, status == GIT_OK.rawValue else {
            let errorMessage = String(cString: git_error_last().pointee.message)
            throw RepositoryError.failedToCreate(errorMessage)
        }

        return Repository(pointer: pointer)
    }

    /// Clone a repository from the specified URL to the specified path.
    ///
    /// - Parameters:
    ///   - url: The URL of the repository to clone.
    ///   - path: The path to clone the repository to.
    ///
    /// - Returns: The cloned repository at the specified path.
    ///
    /// - Throws: `RepositoryError.failedToClone` if the repository cannot be cloned.
    static func clone(
        from remoteURL: URL,
        to localURL: URL,
        options: CloneOptions = .default
    ) async throws -> Repository {
        let repository = try await withUnsafeThrowingContinuation { continuation in
            do {
                let clonedRepository = try clone(from: remoteURL, to: localURL, options: options)
                continuation.resume(returning: clonedRepository)
            } catch {
                continuation.resume(throwing: error)
            }
        }

        return repository
    }

    /// Clone a repository from the specified URL to the specified path with a transfer progress handler.
    ///
    /// - Parameters:
    ///   - url: The URL of the repository to clone.
    ///   - path: The path to clone the repository to.
    ///   - transferProgressHandler: A closure that is called with the transfer progress.
    ///
    /// - Returns: The cloned repository at the specified path.
    ///
    /// - Throws: `RepositoryError.failedToClone` if the repository cannot be cloned.
    static func clone(
        from remoteURL: URL,
        to localURL: URL,
        options: CloneOptions = .default,
        transferProgressHandler: @escaping TransferProgressHandler
    ) async throws -> Repository {
        let repository = try await withUnsafeThrowingContinuation { continuation in
            do {
                let clonedRepository = try cloneWithProgress(
                    from: remoteURL,
                    to: localURL,
                    options: options,
                    transferProgressHandler: transferProgressHandler
                )
                continuation.resume(returning: clonedRepository)
            } catch {
                continuation.resume(throwing: error)
            }
        }

        return repository
    }

    private static func clone(from remoteURL: URL, to localURL: URL, options: CloneOptions) throws -> Repository {
        // Initialize the clone options
        var options = options.gitCloneOptions

        // Set the checkout strategy
        options.checkout_opts.checkout_strategy = GIT_CHECKOUT_SAFE.rawValue

        // Set the transferProgress callback
        options.fetch_opts.callbacks.transfer_progress = { _, _ in
            // If the task is cancelled, return 1 to stop the transfer. Otherwise, return 0 to continue the transfer.
            Task.isCancelled ? 1 : 0
        }

        // Repository pointer
        var pointer: OpaquePointer?

        // Perform the clone operation
        let status = git_clone(&pointer, remoteURL.absoluteString, localURL.path, &options)

        guard let pointer, status == GIT_OK.rawValue else {
            let errorMessage = String(cString: git_error_last().pointee.message)
            throw RepositoryError.failedToClone(errorMessage)
        }

        return Repository(pointer: pointer)
    }

    private static func cloneWithProgress(
        from remoteURL: URL,
        to localURL: URL,
        options: CloneOptions,
        transferProgressHandler: @escaping TransferProgressHandler
    ) throws -> Repository {
        // Define the transferProgress callback
        let transferProgress: git_indexer_progress_cb = { stats, payload in
            guard let stats = stats?.pointee,
                  let payload = payload?.assumingMemoryBound(to: TransferProgressHandler.self),
                  Task.isCancelled == false // Make sure the task is not cancelled
            else {
                // If the stats, the payload is nil or the task is cancelled, return 1 to stop the transfer
                return 1
            }

            // Create a TransferProgress instance from the stats
            let progress = TransferProgress(from: stats)

            // Get the transferProgressHandler from the payload
            let transferProgressHandler = payload.pointee

            // Call the transferProgressHandler
            transferProgressHandler(progress)

            // Return 0 to continue the transfer
            return 0
        }

        // Initialize the clone options
        var options = options.gitCloneOptions

        // Set the checkout strategy
        options.checkout_opts.checkout_strategy = GIT_CHECKOUT_SAFE.rawValue

        // Set the transferProgress callback
        options.fetch_opts.callbacks.transfer_progress = transferProgress

        // Allocate memory for the transferProgressHandler to pass it to the callback
        let transferProgressHandlerPointer = UnsafeMutablePointer<TransferProgressHandler>.allocate(capacity: 1)
        transferProgressHandlerPointer.initialize(to: transferProgressHandler)
        defer { transferProgressHandlerPointer.deallocate() }

        // Set the transferProgressHandler as the payload
        options.fetch_opts.callbacks.payload = UnsafeMutableRawPointer(transferProgressHandlerPointer)

        // Perform the clone operation
        var pointer: OpaquePointer?

        let status = git_clone(&pointer, remoteURL.absoluteString, localURL.path, &options)

        guard let pointer, status == GIT_OK.rawValue else {
            let errorMessage = String(cString: git_error_last().pointee.message)
            throw RepositoryError.failedToClone(errorMessage)
        }

        return Repository(pointer: pointer)
    }
}

// MARK: - Collections

public extension Repository {
    /// Collection of branch operations.
    var branch: BranchCollection {
        BranchCollection(repositoryPointer: pointer)
    }

    /// Collection of repository configuration operations.
    var config: ConfigCollection {
        ConfigCollection(repositoryPointer: pointer)
    }

    /// Collection of global configuration operations.
    static var config: ConfigCollection {
        ConfigCollection()
    }

    /// Collection of index operations.
    internal var index: IndexCollection {
        IndexCollection(repositoryPointer: pointer)
    }

    /// Collection of reference operations.
    var reference: ReferenceCollection {
        ReferenceCollection(repositoryPointer: pointer)
    }

    /// Collection of remote operations.
    var remote: RemoteCollection {
        RemoteCollection(repositoryPointer: pointer)
    }

    /// Collection of stash operations.
    var stash: StashCollection {
        StashCollection(repositoryPointer: pointer)
    }

    /// Collection of tag operations.
    var tag: TagCollection {
        TagCollection(repositoryPointer: pointer)
    }
}

// MARK: - Lookup

public extension Repository {
    /// Lookups an object in the repository by its ID.
    ///
    /// - Parameter id: The ID of the object.
    ///
    /// - Returns: The object with the specified ID.
    ///
    /// - Throws: `ObjectError.invalid` if the object is not found or an error occurs.
    ///
    /// The type of the object must be specified when calling this method.
    ///
    /// Look up a commit by its ID
    /// ```swift
    /// let commit: Commit = try repository.show(id: commitID)
    /// ```
    ///
    /// Look up a tag by its ID
    /// ```swift
    /// let tag: Tag = try repository.show(id: treeID)
    /// ```
    func show<ObjectType: Object>(id: OID) throws -> ObjectType {
        try ObjectFactory.lookupObject(oid: id.raw, repositoryPointer: pointer) as ObjectType
    }
}

// MARK: - Index

public extension Repository {
    /// Adds a file to the index.
    ///
    /// - Parameter path: The file path relative to the repository root directory.
    ///
    /// The path should be relative to the repository root directory.
    /// For example, `README.md` or `Sources/SwiftGitX/Repository.swift`.
    func add(path: String) throws {
        try index.add(path: path)
    }

    /// Adds a file to the index.
    ///
    /// - Parameter file: The file URL.
    func add(file: URL) throws {
        try index.add(file: file)
    }

    /// Adds files to the index.
    ///
    /// - Parameter paths: The paths of the files to add.
    ///
    /// The paths should be relative to the repository root directory.
    /// For example, `README.md` or `Sources/SwiftGitX/Repository.swift`.
    func add(paths: [String]) throws {
        try index.add(paths: paths)
    }

    /// Adds files to the index.
    ///
    /// - Parameter files: The file URLs to add.
    func add(files: [URL]) throws {
        try index.add(files: files)
    }

    // TODO: Investigate these methods

    internal func remove(path: String) throws {
        try index.remove(path: path)
    }

    internal func remove(file: URL) throws {
        try index.remove(file: file)
    }

    internal func remove(paths: [String]) throws {
        try index.remove(paths: paths)
    }

    internal func remove(files: [URL]) throws {
        try index.remove(files: files)
    }

    internal func removeAll() throws {
        try index.removeAll()
    }
}

// MARK: - Commit

public extension Repository {
    /// Create a new commit containing the current contents of the index.
    ///
    /// - Parameter message: The commit message.
    ///
    /// - Returns: The created commit.
    ///
    /// - Throws: `RepositoryError.failedToCommit` if the commit operation fails.
    ///
    /// This method uses the default author and committer information.
    @discardableResult
    func commit(message: String) throws -> Commit {
        // Create a new commit from the index
        var oid = git_oid()

        let status = git_commit_create_from_stage(
            &oid,
            pointer,
            message,
            nil
        )

        guard status == GIT_OK.rawValue else {
            let errorMessage = String(cString: git_error_last().pointee.message)
            throw RepositoryError.failedToCommit(errorMessage)
        }

        // Lookup the resulting commit
        return try ObjectFactory.lookupObject(oid: oid, repositoryPointer: pointer)
    }

    // TODO: Implement merge

    // TODO: Implement rebase

    /// Resets the current branch HEAD to the specified commit and optionally modifies index and working tree files.
    ///
    /// - Parameters:
    ///   - commit: The commit to reset to.
    ///   - resetMode: The type of the reset operation. Default is `.soft`.
    ///
    /// Info: To undo the staged files use `restore` method with `.staged` option.
    ///
    /// With specifying `resetType`, you can optionally modify index and working tree files.
    /// The default is `.soft` which does not modify index and working tree files.
    func reset(to commit: Commit, mode resetMode: ResetOption = .soft) throws {
        // Lookup the commit pointer
        let commitPointer = try ObjectFactory.lookupObjectPointer(
            oid: commit.id.raw,
            type: GIT_OBJECT_COMMIT,
            repositoryPointer: pointer
        )
        defer { git_object_free(commitPointer) }

        // TODO: Implement checkout options

        // Perform the reset operation
        let resetStatus = git_reset(pointer, commitPointer, resetMode.raw, nil)

        guard resetStatus == GIT_OK.rawValue else {
            let errorMessage = String(cString: git_error_last().pointee.message)
            throw RepositoryError.failedToReset(errorMessage)
        }
    }

    /// Copies entries from a commit to the index.
    ///
    /// - Parameters:
    ///   - commit: The commit to reset from.
    ///   - paths: The paths of the files to reset. Default is an empty array which resets all files.
    ///
    /// This method reset the index entries for all paths that match the `paths` to their
    /// state at `commit`. (It does not affect the working tree or the current branch.)
    ///
    /// This means that this method is the opposite of `add()` method.
    /// This command is equivalent to `restore` method with `.staged` option.
    func reset(from commit: Commit, paths: [String]) throws {
        // Lookup the commit pointer
        let headCommitPointer = try ObjectFactory.lookupObjectPointer(
            oid: commit.id.raw,
            type: GIT_OBJECT_COMMIT,
            repositoryPointer: pointer
        )
        defer { git_object_free(headCommitPointer) }

        // Initialize the checkout options
        let status = paths.withGitStrArray { strArray in
            var strArray = strArray

            // Reset the index from the commit
            return git_reset_default(pointer, headCommitPointer, &strArray)
        }

        guard status == GIT_OK.rawValue else {
            let errorMessage = String(cString: git_error_last().pointee.message)
            throw RepositoryError.failedToReset(errorMessage)
        }
    }

    /// Copies entries from a commit to the index.
    ///
    /// - Parameters:
    ///   - commit: The commit to reset from.
    ///   - files: The files of the files to reset. Default is an empty array which resets all files.
    ///
    /// This method reset the index entries for all files that match the `files` to their
    /// state at `commit`. (It does not affect the working tree or the current branch.)
    ///
    /// This means that this method is the opposite of `add()` method.
    /// This command is equivalent to `restore` method with `.staged` option.
    func reset(from commit: Commit, files: [URL]) throws {
        let paths = try files.map {
            try $0.relativePath(from: workingDirectory)
        }

        try reset(from: commit, paths: paths)
    }

    /// Reverts the given commit.
    ///
    /// - Parameters:
    ///   - commit: The commit to revert.
    ///
    /// - Throws: `RepositoryError.failedToRevert` if the revert operation fails.
    ///
    /// This method reverts the given commit, producing changes in the index and working directory.
    func revert(_ commit: Commit) throws {
        // Lookup the commit pointer
        let commitPointer = try ObjectFactory.lookupObjectPointer(
            oid: commit.id.raw,
            type: GIT_OBJECT_COMMIT,
            repositoryPointer: pointer
        )
        defer { git_object_free(commitPointer) }

        // TODO: Implement revert options

        // Perform the revert operation
        let revertStatus = git_revert(pointer, commitPointer, nil)

        guard revertStatus == GIT_OK.rawValue else {
            let errorMessage = String(cString: git_error_last().pointee.message)
            throw RepositoryError.failedToRevert(errorMessage)
        }
    }

    /// Restores working tree files.
    ///
    /// - Parameters:
    ///   - restoreOptions: The restore options. Default is `.workingTree`.
    ///   - paths: The paths of the files to restore. Default is an empty array which restores all files.
    ///
    /// This method restores the working tree files to their state at the HEAD commit.
    ///
    /// This method can also restore the staged files to their state at the HEAD commit.
    func restore(_ restoreOptions: RestoreOption = .workingTree, paths: [String] = []) throws {
        // TODO: Implement source commit option

        // Initialize the checkout options
        let options = CheckoutOptions(
            strategy: [.force, .disablePathSpecMatch],
            paths: paths
        )

        let status = try options.withGitCheckoutOptions { gitCheckoutOptions in
            var gitCheckoutOptions = gitCheckoutOptions

            switch restoreOptions {
            // https://stackoverflow.com/questions/58003030/
            case .workingTree, []:
                return git_checkout_index(pointer, nil, &gitCheckoutOptions)
            case .staged:
                // https://github.com/libgit2/libgit2/issues/3632
                let headCommitPointer = try ObjectFactory.lookupObjectPointer(
                    oid: HEAD.target.id.raw,
                    type: GIT_OBJECT_COMMIT,
                    repositoryPointer: pointer
                )
                defer { git_object_free(headCommitPointer) }

                // Reset the index to HEAD
                return git_reset_default(pointer, headCommitPointer, &gitCheckoutOptions.paths)
            case [.workingTree, .staged]:
                // Checkout HEAD if source is nil
                return git_checkout_tree(pointer, nil, &gitCheckoutOptions)
            default:
                throw RepositoryError.failedToRestore("Invalid restore options")
            }
        }

        guard status == GIT_OK.rawValue else {
            let errorMessage = String(cString: git_error_last().pointee.message)
            throw RepositoryError.failedToRestore(errorMessage)
        }
    }

    /// Restores working tree files.
    ///
    /// - Parameters:
    ///   - restoreOptions: The restore options. Default is `.workingTree`.
    ///   - files: The files to restore. Default is an empty array which restores all files.
    ///
    /// This method restores the working tree files to their state at the HEAD commit.
    ///
    /// This method can also restore the staged files to their state at the HEAD commit.
    func restore(_ restoreOptions: RestoreOption = .workingTree, files: [URL]) throws {
        let paths = try files.map {
            try $0.relativePath(from: workingDirectory)
        }

        try restore(restoreOptions, paths: paths)
    }
}

// MARK: - Switch

public extension Repository {
    /// Switches the HEAD to the specified branch.
    ///
    /// - Parameter branch: The branch to switch to.
    ///
    /// - Throws: `RepositoryError.failedToSwitch` if the switch operation fails.
    ///
    /// If the branch does not exist locally, the method tries to find a remote branch with the same name.
    func `switch`(to branch: Branch) throws {
        // Get the list of local branches. Use list(.local) to throw an error if the operation fails.
        let localBranchExists = try self.branch.list(.local).map(\.fullName).contains(branch.fullName)

        if localBranchExists {
            // Perform the checkout operation
            try checkout(commitID: branch.target.id)

            // Set the HEAD to the reference
            try setHEAD(to: branch)
        } else {
            if let localBranch = try guessBranch(named: branch.name) {
                // Perform the checkout operation
                try checkout(commitID: localBranch.target.id)

                // Set the HEAD to the reference
                try setHEAD(to: localBranch)
            } else {
                throw RepositoryError.failedToSwitch("Failed to checkout the reference")
            }
        }
    }

    /// Switches the HEAD to the specified tag.
    ///
    /// - Parameter tag: The tag to switch to.
    ///
    /// - Throws: `RepositoryError.failedToSwitch` if the switch operation fails.
    ///
    /// The repository will be in a detached HEAD state after switching to the tag.
    func `switch`(to tag: Tag) throws {
        // Perform the checkout operation
        try checkout(commitID: tag.target.id)

        // Set the HEAD to the tag
        try setHEAD(to: tag)
    }

    /// Switches the HEAD to the specified commit.
    ///
    /// - Parameter commit: The commit to switch to.
    ///
    /// - Throws: `RepositoryError.failedToSwitch` if the switch operation fails.
    ///
    /// The repository will be in a detached HEAD state after switching to the commit.
    func `switch`(to commit: Commit) throws {
        // Perform the checkout operation
        try checkout(commitID: commit.id)

        // Set the HEAD to the commit
        try setHEAD(to: commit)
    }

    private func checkout(commitID: OID) throws {
        // Lookup the commit
        let commitPointer = try ObjectFactory.lookupObjectPointer(
            oid: commitID.raw,
            type: GIT_OBJECT_COMMIT,
            repositoryPointer: pointer
        )
        defer { git_object_free(commitPointer) }

        // TODO: Implement checkout options

        // Perform the checkout operation
        let checkoutStatus = git_checkout_tree(pointer, commitPointer, nil)

        guard checkoutStatus == GIT_OK.rawValue else {
            let errorMessage = String(cString: git_error_last().pointee.message)
            throw RepositoryError.failedToSwitch(errorMessage)
        }
    }

    private func setHEAD(to reference: any Reference) throws {
        let status = git_repository_set_head(pointer, reference.fullName)

        guard status == GIT_OK.rawValue else {
            let errorMessage = String(cString: git_error_last().pointee.message)
            throw RepositoryError.failedToSetHEAD(errorMessage)
        }
    }

    private func setHEAD(to commit: Commit) throws {
        var commitID = commit.id.raw
        let status = git_repository_set_head_detached(pointer, &commitID)

        guard status == GIT_OK.rawValue else {
            let errorMessage = String(cString: git_error_last().pointee.message)
            throw RepositoryError.failedToSetHEAD(errorMessage)
        }
    }

    private func guessBranch(named branchName: String) throws -> Branch? {
        // Get the list of remotes
        for remote in try remote.list() {
            // Get the list of remote branches for each remote
            for remoteBranch in remote.branches where remoteBranch.name == branchName {
                // If the tracking branch is found, create a local branch from it
                guard let target = remoteBranch.target as? Commit
                else { continue }

                return try self.branch.create(named: remoteBranch.name, target: target)
            }
        }

        return nil
    }
}

// MARK: - HEAD

public extension Repository {
    /// The HEAD reference of the repository.
    ///
    /// The HEAD is unborn if the repository has no commits. In this case, an error is thrown.
    /// If you want to get the name of the unborn HEAD, use the `config.defaultBranchName` property.
    ///
    /// The HEAD is detached if it points directly to a commit instead of a branch.
    ///
    /// - SeeAlso: If you curious about how HEAD works in Git, you can read Julia Evans's blog posts:
    ///     [How HEAD works in Git](https://jvns.ca/blog/2024/03/08/how-head-works-in-git/)
    ///     and
    ///     [The current branch in Git](https://jvns.ca/blog/2024/03/22/the-current-branch-in-git/)
    var HEAD: any Reference {
        get throws {
            var referencePointer: OpaquePointer?
            defer { git_reference_free(referencePointer) }

            // Get the HEAD reference
            let status = git_repository_head(&referencePointer, pointer)

            guard let referencePointer, status == GIT_OK.rawValue else {
                switch status {
                case GIT_EUNBORNBRANCH.rawValue:
                    throw RepositoryError.unbornHEAD
                default:
                    let errorMessage = String(cString: git_error_last().pointee.message)
                    throw RepositoryError.failedToGetHEAD(errorMessage)
                }
            }

            if git_repository_head_detached(pointer) == 1 {
                // ? Should we create a type for detached HEAD named DetachedHEAD or something similar?
                // ? name: commit abbrev id, fullName: commit id, target: commit?

                // Detached HEAD is a branch reference pointing to a commit, it is name and fullName is "HEAD"
                let detachedHEAD = try Branch(pointer: referencePointer)

                // ? Should we use git describe to get the tag name?
                // swiftformat:disable redundantSelf
                // Lookup if the detached HEAD is a tag reference
                for tag in self.tag where tag.target.id == detachedHEAD.target.id {
                    // If the tag is found, return the tag
                    return tag
                }
                // swiftformat:enable redundantSelf

                // If the tag is not found, return the detached HEAD
                return detachedHEAD
            } else {
                return try Branch(pointer: referencePointer)
            }
        }
    }
}

// MARK: - Diff

public extension Repository {
    /// Get the status of the repository.
    ///
    /// - Parameter options: The status options. Default is `.includeUntracked`.
    ///
    /// - Returns: The status of the repository.
    ///
    /// - Throws: `RepositoryError.failedToGetStatus` if the status operation fails.
    ///
    /// The status of the repository is represented by an array of `StatusEntry` values.
    func status(options optionFlags: StatusOption = .includeUntracked) throws -> [StatusEntry] {
        // Initialize the status options
        var statusOptions = git_status_options()
        let optionsInitStatus = git_status_options_init(&statusOptions, UInt32(GIT_STATUS_OPTIONS_VERSION))

        guard optionsInitStatus == GIT_OK.rawValue else {
            let errorMessage = String(cString: git_error_last().pointee.message)
            throw RepositoryError.failedToGetStatus(errorMessage)
        }

        // Set the status options
        statusOptions.flags = optionFlags.rawValue

        // Get the status list
        var statusList: OpaquePointer?
        defer { git_status_list_free(statusList) }

        let statusListInitStatus = git_status_list_new(&statusList, pointer, &statusOptions)

        guard statusListInitStatus == GIT_OK.rawValue else {
            let errorMessage = String(cString: git_error_last().pointee.message)
            throw RepositoryError.failedToGetStatus(errorMessage)
        }

        // Get the status count
        let statusCount = git_status_list_entrycount(statusList)

        // Create an array to store the status entries
        var statusEntries: [StatusEntry] = []

        // Iterate over the status entries
        for index in 0 ..< statusCount {
            // Get the status entry
            let statusEntryPointer = git_status_byindex(statusList, index)

            // ? Should we handle the status entry differently if it's nil?
            guard let statusEntryPointer else {
                throw RepositoryError.failedToGetStatus("Failed to get the status entry")
            }

            // Create a StatusEntry instance from the status entry
            let statusEntry = StatusEntry(raw: statusEntryPointer.pointee)

            // Append the status entry to the status entries array
            statusEntries.append(statusEntry)
        }

        return statusEntries
    }

    /// Get the status of the specified path.
    ///
    /// - Parameter path: The path of the file.
    ///
    /// - Returns: The status of the file.
    ///
    /// - Throws: `RepositoryError.failedToGetStatus` if the status operation fails.
    ///
    /// The path should be relative to the repository root directory. For example, `README.md` or
    /// `Sources/SwiftGitX/Repository.swift`.
    ///
    /// The status of the file is represented by an array of `StatusEntry.Status` values.
    /// Because a file can have multiple statuses. For example, a file can be both
    /// ``SwiftGitX/StatusEntry/Status-swift.enum/indexNew`` and
    /// ``SwiftGitX/StatusEntry/Status-swift.enum/workingTreeModified``.
    func status(path: String) throws -> [StatusEntry.Status] {
        var statusFlags: UInt32 = 0

        let status = git_status_file(&statusFlags, pointer, path)

        guard status == GIT_OK.rawValue else {
            let errorMessage = String(cString: git_error_last().pointee.message)
            throw RepositoryError.failedToGetStatus(errorMessage)
        }

        return StatusEntry.Status.from(statusFlags)
    }

    // ? Should we return Set<StatusEntry.Status> instead of [StatusEntry.Status]?
    /// Get the status of the specified file.
    ///
    /// - Parameter file: The file URL.
    ///
    /// - Returns: The status of the file.
    ///
    /// - Throws: `RepositoryError.failedToGetStatus` if the status operation fails.
    ///
    /// The status of the file is represented by an array of `StatusEntry.Status` values.
    /// Because a file can have multiple statuses. For example, a file can be both
    /// ``SwiftGitX/StatusEntry/Status-swift.enum/indexNew`` and
    /// ``SwiftGitX/StatusEntry/Status-swift.enum/workingTreeModified``.
    func status(file: URL) throws -> [StatusEntry.Status] {
        let path = try file.relativePath(from: workingDirectory)

        return try status(path: path)
    }

    /// Get the diff between HEAD commit and its parent.
    ///
    /// - Returns: The diff between the HEAD commit and its parent.
    ///
    /// - Throws: `RepositoryError.failedToGetDiff` if the diff operation fails.
    func diff() throws -> Diff {
        // Get the HEAD commit
        guard let headCommit = try HEAD.target as? Commit else {
            throw RepositoryError.failedToGetDiff("Failed to get the HEAD commit")
        }

        return try diff(commit: headCommit)
    }

    /// Get the diff between given commit and its parent.
    ///
    /// - Parameter commit: The commit to get the diff.
    ///
    /// - Returns: The diff between the commit and its parent.
    ///
    /// - Throws: `RepositoryError.failedToGetDiff` if the diff operation fails.
    func diff(commit: Commit) throws -> Diff {
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
    func diff(from fromObject: any Object, to toObject: any Object) throws -> Diff {
        // Get the diff options
        var diffOptions = git_diff_options()
        let optionsInitStatus = git_diff_init_options(&diffOptions, UInt32(GIT_DIFF_OPTIONS_VERSION))

        guard optionsInitStatus == GIT_OK.rawValue else {
            let errorMessage = String(cString: git_error_last().pointee.message)
            throw RepositoryError.failedToGetDiff(errorMessage)
        }

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
        var diffPointer: OpaquePointer?
        defer { git_diff_free(diffPointer) }

        let diffStatus = git_diff_tree_to_tree(
            &diffPointer,
            pointer,
            fromObjectTreePointer,
            toObjectTreePointer,
            &diffOptions
        )

        guard let diffPointer, diffStatus == GIT_OK.rawValue else {
            let errorMessage = String(cString: git_error_last().pointee.message)
            throw RepositoryError.failedToGetDiff(errorMessage)
        }

        return Diff(pointer: diffPointer)
    }
}

// MARK: - Log

public extension Repository {
    /// Retrieves the commit history of the repository.
    ///
    /// - Parameter sorting: The sorting option for the commit history. Defaults to `.none`.
    ///
    /// - Returns: A `CommitSequence` representing the commit history.
    ///
    /// - Throws: A `ReferenceError.invalid` error if the reference type is invalid.
    func log(sorting: LogSortingOption = .none) throws -> CommitSequence {
        try log(from: HEAD, sorting: sorting)
    }

    /// Retrieves the commit history from the given reference.
    ///
    /// - Parameters:
    ///   - reference: The reference to start the commit history from.
    ///   - sorting: The option to sort the commit history. Default is `.none`.
    ///
    /// - Returns: A `CommitSequence` representing the commit history.
    ///
    /// - Throws: A `ReferenceError.invalid` error if the reference type is invalid.
    func log(from reference: any Reference, sorting: LogSortingOption = .none) throws -> CommitSequence {
        if let commit = reference.target as? Commit {
            return log(from: commit, sorting: sorting)
        } else {
            throw ReferenceError.invalid("Invalid reference type")
        }
    }

    /// Retrieves the commit history from the specified commit.
    ///
    /// - Parameters:
    ///   - commit: The commit to start the commit history from.
    ///   - sorting: The sorting option for the commit sequence. Default is `.none`.
    ///
    /// - Returns: A `CommitSequence` representing the commit history.
    func log(from commit: Commit, sorting: LogSortingOption = .none) -> CommitSequence {
        CommitSequence(root: commit, sorting: sorting, repositoryPointer: pointer)
    }
}

// MARK: - Remote

public extension Repository {
    /// Push changes of the current branch to the remote.
    ///
    /// - Parameter remote: The remote to push the changes to.
    ///
    /// This method uses the default refspecs to push the changes to the remote.
    ///
    /// If the remote is not specified, the upstream of the current branch is used
    /// and if the upstream branch is not found, the `origin` remote is used.
    func push(remote: Remote? = nil) async throws {
        try await withUnsafeThrowingContinuation { continuation in
            do {
                try push(remote: remote)
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Fetch the objects and refs from the other repository.
    ///
    /// - Parameter remote: The remote to fetch the changes from.
    ///
    /// This method uses the default refspecs to fetch the changes from the remote.
    ///
    /// If the remote is not specified, the upstream of the current branch is used
    /// and if the upstream branch is not found, the `origin` remote is used.
    func fetch(remote: Remote? = nil) async throws {
        try await withUnsafeThrowingContinuation { continuation in
            do {
                try fetch(remote: remote)
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
