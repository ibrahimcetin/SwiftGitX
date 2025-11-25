//
//  StashCollection.swift
//  SwiftGitX
//
//  Created by İbrahim Çetin on 24.11.2025.
//

import libgit2

/// A collection of stashes and their operations.
///
/// `StashCollection` provides a Swift interface to libgit2's stash functionality,
/// allowing you to save, apply, list, and remove stashed changes in a repository.
///
/// Stashes store uncommitted changes temporarily, creating a commit that is referenced
/// by `refs/stash`.
public struct StashCollection: Sequence {
    private let repositoryPointer: OpaquePointer

    init(repositoryPointer: OpaquePointer) {
        self.repositoryPointer = repositoryPointer
    }

    /// Returns a list of stashes.
    ///
    /// Iterates over all stashed states in the repository.
    ///
    /// - Returns: An array of ``StashEntry`` objects representing each stashed state.
    ///
    /// - Throws: ``SwiftGitXError`` if the stashes could not be listed.
    public func list() throws(SwiftGitXError) -> [StashEntry] {
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

        try SwiftGitXError.check(status, operation: .stashList)

        return context.stashEntries
    }

    /// Saves the local modifications to the stash.
    ///
    /// Creates a new commit containing the stashed state and updates the `refs/stash` reference.
    ///
    /// - Parameters:
    ///   - message: Optional description for the stashed state.
    ///   - options: Options controlling the stashing process (see ``StashOption``).
    ///   - stasher: The identity of the person performing the stashing. If `nil`, uses the repository's default signature.
    ///
    /// - Throws: ``SwiftGitXError`` if the stash could not be saved.
    ///
    /// - Note: Returns ``SwiftGitXError/Code/notFound`` when there's nothing to stash (no local modifications).
    public func save(
        message: String? = nil,
        options: StashOption = .default,
        stasher: Signature? = nil
    ) throws(SwiftGitXError) {
        // Get the default signature if none is provided
        let resolvedStasher: Signature
        if let stasher {
            resolvedStasher = stasher
        } else {
            resolvedStasher = try Signature.default(in: repositoryPointer)
        }

        // Create a pointer to the stasher
        let stasherPointer = try ObjectFactory.makeSignaturePointer(signature: resolvedStasher)
        defer { git_signature_free(stasherPointer) }

        // Save the local modifications to the stash
        var oid = git_oid()

        try git(operation: .stashSave) {
            git_stash_save(
                &oid,
                repositoryPointer,
                stasherPointer,
                message,
                options.rawValue
            )
        }
    }

    // TODO: Implement apply options
    /// Applies the stash entry to the working directory.
    ///
    /// Applies a stashed state back onto the working directory.
    /// The stash is not removed from the stash list.
    ///
    /// - Parameter stashEntry: The stash entry to apply. If `nil`, applies the most recent stash (index 0).
    ///
    /// - Throws: ``SwiftGitXError`` if the stash could not be applied.
    ///
    /// - Note: May fail with merge conflicts. Consider handling ``SwiftGitXError/Code/mergeConflict``.
    public func apply(_ stashEntry: StashEntry? = nil) throws(SwiftGitXError) {
        let stashIndex = stashEntry?.index ?? 0

        // Apply the stash entry
        // TODO: Handle GIT_EMERGECONFLICT
        try git(operation: .stashApply) {
            git_stash_apply(repositoryPointer, stashIndex, nil)
        }
    }

    // TODO: Implement apply options
    /// Applies the stash entry to the working directory and removes it from the stash list.
    ///
    /// Applies a stashed state and removes it upon successful application.
    /// If application fails, the stash is not removed.
    ///
    /// - Parameter stashEntry: The stash entry to pop. If `nil`, pops the most recent stash (index 0).
    ///
    /// - Throws: ``SwiftGitXError`` if the stash could not be applied or removed.
    ///
    /// - Note: May fail with merge conflicts. Consider handling ``SwiftGitXError/Code/mergeConflict``.
    public func pop(_ stashEntry: StashEntry? = nil) throws(SwiftGitXError) {
        let stashIndex = stashEntry?.index ?? 0

        // Pop the stash entry
        // TODO: Handle GIT_EMERGECONFLICT
        try git(operation: .stashPop) {
            git_stash_pop(repositoryPointer, stashIndex, nil)
        }
    }

    /// Removes the stash entry from the stash list.
    ///
    /// Removes a single stashed state from the stash list without applying it.
    ///
    /// - Parameter stashEntry: The stash entry to drop. If `nil`, drops the most recent stash (index 0).
    ///
    /// - Throws: ``SwiftGitXError`` if the stash entry could not be removed.
    public func drop(_ stashEntry: StashEntry? = nil) throws(SwiftGitXError) {
        let stashIndex = stashEntry?.index ?? 0

        // Drop the stash entry
        try git(operation: .stashDrop) {
            git_stash_drop(repositoryPointer, stashIndex)
        }
    }

    // TODO: Create a true iterator
    public func makeIterator() -> StashIterator {
        StashIterator(entries: (try? list()) ?? [])
    }
}

extension SwiftGitXError.Operation {
    public static let stashList = Self(rawValue: "stashList")
    public static let stashSave = Self(rawValue: "stashSave")
    public static let stashApply = Self(rawValue: "stashApply")
    public static let stashPop = Self(rawValue: "stashPop")
    public static let stashDrop = Self(rawValue: "stashDrop")
}
