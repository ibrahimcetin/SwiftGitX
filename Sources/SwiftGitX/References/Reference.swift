//
//  Reference.swift
//  SwiftGitX
//
//  Created by İbrahim Çetin on 24.11.2025.
//

/// A reference representation in a Git repository.
public protocol Reference: Equatable, Hashable, Sendable {
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

    /// The type of the reference.
    ///
    /// It can be either `direct` or `symbolic`.
    var referenceType: ReferenceType { get }
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
