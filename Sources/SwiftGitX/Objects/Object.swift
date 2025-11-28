//
//  Object.swift
//  SwiftGitX
//
//  Created by İbrahim Çetin on 24.11.2025.
//

/// An object representation that can be stored in a Git repository.
public protocol Object: Identifiable, Equatable, Hashable, Sendable {
    /// The id of the object.
    var id: OID { get }

    /// The type of the object.
    var type: ObjectType { get }
}
