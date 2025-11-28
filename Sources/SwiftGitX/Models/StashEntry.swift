import Foundation

/// A stash entry representation in the repository.
public struct StashEntry: Equatable, Hashable, Sendable {
    /// The index of the entry.
    public let index: Int

    /// The target commit of the entry.
    public let target: Commit

    /// The message associated with the entry.
    public let message: String

    /// The signature of the stasher.
    public let stasher: Signature

    /// The date of the stash entry.
    public let date: Date
}
