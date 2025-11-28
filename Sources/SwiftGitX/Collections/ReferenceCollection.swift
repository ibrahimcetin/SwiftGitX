//
//  ReferenceCollection.swift
//  SwiftGitX
//
//  Created by İbrahim Çetin on 24.11.2025.
//

import libgit2

/// A collection of references and their operations.
public struct ReferenceCollection: Sequence, Sendable {
    nonisolated(unsafe) private let repositoryPointer: OpaquePointer

    init(repositoryPointer: OpaquePointer) {
        self.repositoryPointer = repositoryPointer
    }

    /// Retrieve a reference by its full name.
    ///
    /// - Parameter fullName: The full name of the reference.
    ///   (e.g. `refs/heads/main`, `refs/tags/v1.0.0`,`refs/remotes/origin/main`)
    ///
    /// - Returns: The reference with the specified name, or `nil` if it doesn't exist.
    public subscript(fullName: String) -> (any Reference)? {
        try? get(named: fullName)
    }

    /// Returns a reference by its full name.
    ///
    /// - Parameter fullName: The full name of the reference.
    ///   (e.g. `refs/heads/main`, `refs/tags/v1.0.0`,`refs/remotes/origin/main`)
    ///
    /// - Returns: The reference with the specified name.
    public func get(named fullName: String) throws(SwiftGitXError) -> (any Reference) {
        let referencePointer = try ReferenceFactory.lookupReferencePointer(
            fullName: fullName,
            repositoryPointer: repositoryPointer
        )
        defer { git_reference_free(referencePointer) }

        return try ReferenceFactory.makeReference(pointer: referencePointer)
    }

    /// Returns a list of references.
    ///
    /// - Parameter glob: A glob pattern to filter the references (e.g. `refs/heads/*`, `refs/tags/*`).
    /// Default is `nil`.
    ///
    /// - Returns: A list of references.
    ///
    /// The reference can be a `Branch`, a `Tag`.
    public func list(glob: String? = nil) throws(SwiftGitXError) -> [any Reference] {
        var referenceIteratorPointer: UnsafeMutablePointer<git_reference_iterator>?
        defer { git_reference_iterator_free(referenceIteratorPointer) }

        try git(operation: .referenceList) {
            if let glob {
                git_reference_iterator_glob_new(&referenceIteratorPointer, repositoryPointer, glob)
            } else {
                git_reference_iterator_new(&referenceIteratorPointer, repositoryPointer)
            }
        }

        var references = [any Reference]()
        while true {
            do {
                let referencePointer = try git(operation: .referenceList) {
                    var referencePointer: OpaquePointer?
                    let status = git_reference_next(&referencePointer, referenceIteratorPointer)
                    return (referencePointer, status)
                }
                defer { git_reference_free(referencePointer) }

                let reference = try ReferenceFactory.makeReference(pointer: referencePointer)
                references.append(reference)
            } catch  where error.code == .iterOver {
                break
            } catch {
                throw error
            }
        }

        return references
    }

    public func makeIterator() -> ReferenceIterator {
        ReferenceIterator(repositoryPointer: repositoryPointer)
    }
}

extension SwiftGitXError.Operation {
    public static let referenceList = Self(rawValue: "referenceList")
}
