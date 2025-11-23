import libgit2

public enum ReferenceError: Error, Equatable {
    case invalid(String)
    case notFound
}

/// A reference representation in a Git repository.
public protocol Reference: Equatable, Hashable {
    /// The target of the reference.
    var target: any Object { get }

    /// The name of the reference.
    ///
    /// For example, `main`.
    var name: String { get }

    /// The full name of the reference.
    ///
    /// For example, `refs/heads/main`.
    var fullName: String { get }
}

extension Reference {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.target.id == rhs.target.id && lhs.name == rhs.name && lhs.fullName == rhs.fullName
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(target.id)
        hasher.combine(name)
        hasher.combine(fullName)
    }
}
