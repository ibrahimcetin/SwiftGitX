import libgit2

public enum ReferenceCollectionError: Error {
    case failedToList(String)
}

/// A collection of references and their operations.
public struct ReferenceCollection: Sequence {
    private var repositoryPointer: OpaquePointer {
        get {
            repositoryPointerProtector.read { $0 }
        }
        set {
            repositoryPointerProtector.write(newValue)
        }
    }

    private let repositoryPointerProtector: Protected<OpaquePointer>

    init(repositoryPointer: OpaquePointer) {
        self.repositoryPointerProtector = Protected(repositoryPointer)
    }

    // * I am not sure calling `git_error_last()` from a computed property is safe.
    // * Because libgit2 docs say that "The error message is thread-local. The git_error_last() call must happen on the
    // * same thread as the error in order to get the message."
    // * But, I think it is worth a try.
    private var errorMessage: String {
        String(cString: git_error_last().pointee.message)
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
    ///
    /// - Throws: A `ReferenceError` if an error occurs.
    public func get(named fullName: String) throws -> (any Reference) {
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
    ///
    /// - Throws: A `ReferenceCollectionError.failedToList` if an error occurs.
    public func list(glob: String? = nil) throws -> [any Reference] {
        var referenceIterator: UnsafeMutablePointer<git_reference_iterator>?
        defer { git_reference_iterator_free(referenceIterator) }

        let status = if let glob {
            git_reference_iterator_glob_new(&referenceIterator, repositoryPointer, glob)
        } else {
            git_reference_iterator_new(&referenceIterator, repositoryPointer)
        }

        guard status == GIT_OK.rawValue else {
            throw ReferenceCollectionError.failedToList(errorMessage)
        }

        var references = [any Reference]()
        while true {
            var referencePointer: OpaquePointer?
            defer { git_reference_free(referencePointer) }

            let nextStatus = git_reference_next(&referencePointer, referenceIterator)

            if nextStatus == GIT_ITEROVER.rawValue {
                break
            } else if nextStatus != GIT_OK.rawValue {
                throw ReferenceCollectionError.failedToList(errorMessage)
            } else if let referencePointer {
                let reference = try ReferenceFactory.makeReference(pointer: referencePointer)
                references.append(reference)
            } else {
                throw ReferenceCollectionError.failedToList("Failed to get reference")
            }
        }

        return references
    }

    public func makeIterator() -> ReferenceIterator {
        ReferenceIterator(repositoryPointer: repositoryPointer)
    }
}
