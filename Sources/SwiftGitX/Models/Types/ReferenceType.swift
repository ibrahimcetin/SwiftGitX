//
//  ReferenceType.swift
//  SwiftGitX
//
//  Created by İbrahim Çetin on 29.11.2025.
//

import libgit2

/// The type of a Git reference.
///
/// References can be direct (pointing to a commit) or symbolic (pointing to another reference).
public enum ReferenceType: Equatable, Hashable, Sendable {
    /// An invalid reference.
    case invalid

    /// A direct reference that points directly to an object (commit).
    case direct

    /// A symbolic reference that points to another reference (e.g., HEAD, origin/HEAD).
    ///
    /// - Parameter target: The full name of the target reference.
    ///
    /// - Note: You can use ``isSymbolic`` to check if the reference is symbolic.
    case symbolic(target: String)

    /// All reference types.
    case all

    var raw: git_reference_t {
        switch self {
        case .invalid:
            GIT_REFERENCE_INVALID
        case .direct:
            GIT_REFERENCE_DIRECT
        case .symbolic:
            GIT_REFERENCE_SYMBOLIC
        case .all:
            GIT_REFERENCE_ALL
        }
    }
}

extension ReferenceType {
    /// Checks if the reference is direct.
    public var isDirect: Bool {
        self == .direct
    }

    /// Checks if the reference is symbolic.
    public var isSymbolic: Bool {
        switch self {
        case .symbolic:
            true
        default:
            false
        }
    }
}
