import libgit2

public enum StashCollectionError: Error, Equatable {
    case noLocalChangesToSave
    case failedToSave(String)
    case failedToList(String)
    case failedToApply(String)
    case failedToDrop(String)
    case failedToPop(String)
}

/// A collection of stashes and their operations.
public struct StashCollection: Sequence {
    private let repositoryPointer: OpaquePointer

    init(repositoryPointer: OpaquePointer) {
        self.repositoryPointer = repositoryPointer
    }

    private var errorMessage: String {
        String(cString: git_error_last().pointee.message)
    }

    /// Returns a list of stashes.
    ///
    /// - Returns: An array of stashes.
    ///
    /// - Throws: `StashCollectionError.failedToList` if the stashes could not be listed.
    public func list() throws -> [StashEntry] {
        // Define a context to store the stashes and the repository pointer
        class Context {
            var stashEntries: [StashEntry]
            var repositoryPointer: OpaquePointer

            init(stashEntries: [StashEntry], repositoryPointer: OpaquePointer) {
                self.stashEntries = stashEntries
                self.repositoryPointer = repositoryPointer
            }
        }

        // Define a callback to process each stash entry
        let callback: git_stash_cb = { index, message, oid, payload in
            guard let context = payload?.assumingMemoryBound(to: Context.self).pointee else {
                return -1
            }

            guard let oid = oid?.pointee, let message else {
                return -1
            }

            guard
                let target: Commit = try? ObjectFactory.lookupObject(
                    oid: oid,
                    repositoryPointer: context.repositoryPointer
                )
            else { return -1 }

            let stashEntry = StashEntry(
                index: index,
                target: target,
                message: String(cString: message),
                stasher: target.author,
                date: target.date
            )
            context.stashEntries.append(stashEntry)

            return 0
        }

        // List the stashes
        var context = Context(stashEntries: [], repositoryPointer: repositoryPointer)
        let status = withUnsafeMutablePointer(to: &context) { contextPointer in
            git_stash_foreach(
                repositoryPointer,
                callback,
                contextPointer
            )
        }

        guard status == GIT_OK.rawValue else {
            throw StashCollectionError.failedToList("Failed to list stashes")
        }

        return context.stashEntries
    }

    /// Saves the local modifications to the stash.
    ///
    /// - Parameters:
    ///   - message: The message associated with the stash.
    ///   - options: The options to use when saving the stash.
    ///   - stasher: The signature of the stasher.
    ///
    /// - Throws: `StashCollectionError.failedToSave` if the stash could not be saved,
    /// `StashCollectionError.noLocalChangesToSave` if there are no local changes to save,
    public func save(
        message: String? = nil,
        options: StashOption = .default,
        stasher: Signature? = nil
    ) throws {
        // Get the default signature if none is provided
        let stasher = try stasher ?? Signature.default(in: repositoryPointer)

        // Create a pointer to the stasher
        let stasherPointer = try ObjectFactory.makeSignaturePointer(signature: stasher)
        defer { git_signature_free(stasherPointer) }

        // Save the local modifications to the stash
        var oid = git_oid()
        let status = git_stash_save(
            &oid,
            repositoryPointer,
            stasherPointer,
            message,
            options.rawValue
        )

        guard status == GIT_OK.rawValue else {
            switch status {
            case GIT_ENOTFOUND.rawValue:
                throw StashCollectionError.noLocalChangesToSave
            default:
                throw StashCollectionError.failedToSave(errorMessage)
            }
        }
    }

    // TODO: Implement apply options
    /// Applies the stash entry to the working directory.
    ///
    /// - Parameter stashEntry: The stash entry to apply.
    ///
    /// - Throws: `StashCollectionError.failedToApply` if the stash entry could not be applied.
    public func apply(_ stashEntry: StashEntry? = nil) throws {
        let stashIndex = stashEntry?.index ?? 0

        // Apply the stash entry
        // TODO: Handle GIT_EMERGECONFLICT
        let status = git_stash_apply(repositoryPointer, stashIndex, nil)

        guard status == GIT_OK.rawValue else {
            throw StashCollectionError.failedToApply(errorMessage)
        }
    }

    // TODO: Implement apply options
    /// Applies the stash entry to the working directory and removes it from the stash list.
    ///
    /// - Parameter stashEntry: The stash entry to pop.
    ///
    /// - Throws: `StashCollectionError.failedToPop` if the stash entry could not be popped.
    public func pop(_ stashEntry: StashEntry? = nil) throws {
        let stashIndex = stashEntry?.index ?? 0

        // Pop the stash entry
        // TODO: Handle GIT_EMERGECONFLICT
        let status = git_stash_pop(repositoryPointer, stashIndex, nil)

        guard status == GIT_OK.rawValue else {
            throw StashCollectionError.failedToPop(errorMessage)
        }
    }

    /// Removes the stash entry from the stash list.
    ///
    /// - Parameter stashEntry: The stash entry to drop.
    ///
    /// - Throws: `StashCollectionError.failedToDrop` if the stash entry could not be dropped.
    public func drop(_ stashEntry: StashEntry? = nil) throws {
        let stashIndex = stashEntry?.index ?? 0

        // Drop the stash entry
        let status = git_stash_drop(repositoryPointer, stashIndex)

        guard status == GIT_OK.rawValue else {
            throw StashCollectionError.failedToDrop(errorMessage)
        }
    }

    // TODO: Create a true iterator
    public func makeIterator() -> StashIterator {
        StashIterator(entries: (try? list()) ?? [])
    }
}
