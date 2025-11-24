import libgit2

enum ReferenceFactory {
    /// Creates a reference based on the given pointer.
    ///
    /// - Parameter pointer: The reference pointer.
    ///
    /// - Returns: A reference of type `Branch` or `Tag` based on the type of the reference.
    static func makeReference(pointer: OpaquePointer) throws(SwiftGitXError) -> any Reference {
        if git_reference_is_branch(pointer) == 1 || git_reference_is_remote(pointer) == 1 {
            return try Branch(pointer: pointer)
        } else if git_reference_is_tag(pointer) == 1 {
            // Tag is a object as well as a reference.
            // But we need to get `git_tag` object to get the tag properties.
            // To get the `git_tag` object, we need to lookup the tag by its name.

            // Get the tag name and the repository pointer
            let rawName = git_reference_shorthand(pointer)
            let repositoryPointer = git_reference_owner(pointer)

            guard let rawName, let repositoryPointer else {
                throw SwiftGitXError(code: .error, category: .reference, message: "Invalid reference")
            }

            // Lookup the tag by its full name
            let tag = try ObjectFactory.lookupTag(
                name: String(cString: rawName),
                repositoryPointer: repositoryPointer
            )

            return tag
        } else {
            throw SwiftGitXError(code: .error, category: .reference, message: "Invalid reference type")
        }
    }

    /// Looks up a reference pointer in a given repository.
    ///
    /// - Parameters:
    ///   - fullName: The full name of the reference.
    ///   - repositoryPointer: The opaque pointer to the repository.
    ///
    /// - Returns: The opaque pointer to the reference.
    ///
    /// - Important: The returned reference pointer must be released with `git_reference_free` when no longer needed.
    static func lookupReferencePointer(
        fullName: String,
        repositoryPointer: OpaquePointer
    ) throws(SwiftGitXError) -> OpaquePointer {
        let pointer = try git {
            var pointer: OpaquePointer?
            let status = git_reference_lookup(&pointer, repositoryPointer, fullName)
            return (pointer, status)
        }

        return pointer
    }

    static func lookupBranchPointer(
        name: String,
        type: git_branch_t,
        repositoryPointer: OpaquePointer
    ) throws(SwiftGitXError) -> OpaquePointer {
        let pointer = try git {
            var pointer: OpaquePointer?
            let status = git_branch_lookup(&pointer, repositoryPointer, name, type)
            return (pointer, status)
        }

        return pointer
    }

    static func lookupRemotePointer(
        name: String,
        repositoryPointer: OpaquePointer
    ) throws(SwiftGitXError) -> OpaquePointer {
        let pointer = try git {
            var pointer: OpaquePointer?
            let status = git_remote_lookup(&pointer, repositoryPointer, name)
            return (pointer, status)
        }

        return pointer
    }
}
