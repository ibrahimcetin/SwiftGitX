/// An internal protocol for types that can be represented by a raw libgit2 struct.
protocol LibGit2RawRepresentable: Equatable, Hashable, Sendable {
    associatedtype RawType

    /// The raw libgit2 struct that this type wraps.
    var raw: RawType { get }

    /// Initializes the type with a raw libgit2 struct.
    ///
    /// - Parameter raw: The raw libgit2 struct.
    init(raw: RawType)
}
