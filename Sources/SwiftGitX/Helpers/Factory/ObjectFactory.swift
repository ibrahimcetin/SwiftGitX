//
//  ObjectFactory.swift
//  SwiftGitX
//
//  Created by İbrahim Çetin on 23.11.2025.
//

import libgit2

/// An object factory that creates objects from pointers or object ids.
///
/// The factory creates objects of type `Commit`, `Tree`, `Blob`, or `Tag`.
/// - Note: This is an internal API. Must be used for the specified object types.
enum ObjectFactory {
    // ? Should we pass `type` parameter to restrict the object type?
    /// Lookups an object of the specified type using the given object ID and repository pointer.
    ///
    /// - Parameters:
    ///   - oid: The raw object ID of the desired object.
    ///   - repositoryPointer: The pointer to the repository.
    ///
    /// - Returns: A object of the specified type.
    static func lookupObject<ObjectType: Object>(
        oid: git_oid,
        repositoryPointer: OpaquePointer
    ) throws(SwiftGitXError) -> ObjectType {
        let object = try lookupObject(oid: oid, repositoryPointer: repositoryPointer)

        guard let object = object as? ObjectType else {
            throw SwiftGitXError(
                code: .error, category: .object,
                message: "Object is not of type \(ObjectType.self)"
            )
        }

        return object
    }

    /// Lookups an object of any type from the given object ID in the specified repository.
    ///
    /// - Parameters:
    ///   - oid: The raw object ID of the desired object.
    ///   - repositoryPointer: The pointer to the repository.
    ///
    /// - Returns: A object of type `Commit`, `Tree`, `Blob`, or `Tag` based on the type of the object.
    static func lookupObject(oid: git_oid, repositoryPointer: OpaquePointer) throws(SwiftGitXError) -> any Object {
        let pointer = try lookupObjectPointer(oid: oid, type: GIT_OBJECT_ANY, repositoryPointer: repositoryPointer)
        defer { git_object_free(pointer) }

        return try makeObject(pointer: pointer)
    }

    static func lookupCommit(oid: git_oid, repositoryPointer: OpaquePointer) throws(SwiftGitXError) -> Commit {
        let pointer = try lookupObjectPointer(oid: oid, type: GIT_OBJECT_COMMIT, repositoryPointer: repositoryPointer)
        defer { git_object_free(pointer) }

        return try Commit(pointer: pointer)
    }

    static func lookupTag(name: String, repositoryPointer: OpaquePointer) throws(SwiftGitXError) -> Tag {
        // Add the prefix to the tag name
        let fullName = GitDirectoryConstants.tags + name

        // Lookup the tag by its name
        let objectPointer = try ObjectFactory.lookupObjectPointer(
            revision: fullName,
            repositoryPointer: repositoryPointer
        )
        defer { git_object_free(objectPointer) }

        // Create a tag object based on the object pointer
        switch git_object_type(objectPointer) {
        // If the tag is annotated, its type will be `GIT_OBJECT_TAG`.
        case GIT_OBJECT_TAG:
            let tag = try Tag(pointer: objectPointer)

            // If the tag name is the same as the requested name, return the tag.
            // If the tag name is different, it means it is a lightweight tag pointing to a tag object.
            return tag.name == name ? tag : Tag(name: name, target: tag)

        // If the tag is lightweight, its id will be the same as the target object.
        // So, its type will be the type of the target object.
        default:
            let target = try ObjectFactory.makeObject(pointer: objectPointer)
            return Tag(name: name, target: target)
        }
    }

    /// Creates an object based on the given object pointer.
    ///
    /// - Parameters:
    ///    - pointer: The opaque pointer representing the object.
    ///
    /// - Returns: A object of type `Commit`, `Tree`, `Blob`, or `Tag` based on the type of the object.
    private static func makeObject(pointer: OpaquePointer) throws(SwiftGitXError) -> any Object {
        let type = git_object_type(pointer)

        return switch type {
        case GIT_OBJECT_COMMIT:
            try Commit(pointer: pointer)
        case GIT_OBJECT_TREE:
            try Tree(pointer: pointer)
        case GIT_OBJECT_BLOB:
            try Blob(pointer: pointer)
        case GIT_OBJECT_TAG:
            try Tag(pointer: pointer)
        default:
            throw SwiftGitXError(code: .error, category: .object, message: "Invalid object type")
        }
    }

    /// Creates an object pointer from the given object ID and type in the specified repository.
    ///
    /// - Parameters:
    ///   - oid: The raw object id.
    ///   - type: The raw type of the object.
    ///   - repositoryPointer: The pointer to the repository.
    ///
    /// - Returns: A pointer to the object.
    ///
    /// - Important: The returned object pointer must be released with `git_object_free` when no longer needed.
    static func lookupObjectPointer(
        oid: git_oid,
        type: git_object_t,
        repositoryPointer: OpaquePointer
    ) throws(SwiftGitXError) -> OpaquePointer {
        var oid = oid

        let objectPointer = try git {
            var pointer: OpaquePointer?
            // Perform the object lookup operation
            let status = git_object_lookup(&pointer, repositoryPointer, &oid, type)
            // Return the pointer and status
            return (pointer, status)
        }

        return objectPointer
    }

    static func lookupObject(revision: String, repositoryPointer: OpaquePointer) throws(SwiftGitXError) -> any Object {
        let objectPointer = try lookupObjectPointer(revision: revision, repositoryPointer: repositoryPointer)
        defer { git_object_free(objectPointer) }

        return try makeObject(pointer: objectPointer)
    }

    static func lookupObjectPointer(
        revision: String,
        repositoryPointer: OpaquePointer
    ) throws(SwiftGitXError) -> OpaquePointer {
        let objectPointer = try git {
            var pointer: OpaquePointer?
            // Perform the object lookup operation
            let status = git_revparse_single(&pointer, repositoryPointer, revision)
            return (pointer, status)
        }

        return objectPointer
    }

    /// Peels an object to the specified type.
    ///
    /// - Parameters:
    ///   - oid: The object id of the object to peel.
    ///   - type: The target type of the object.
    ///
    /// - Returns: A pointer to the peeled object.
    ///
    /// - Important: The returned object pointer must be released with `git_object_free` when no longer needed.
    static func peelObjectPointer(
        oid: git_oid,
        targetType: git_object_t,
        repositoryPointer: OpaquePointer
    ) throws(SwiftGitXError) -> OpaquePointer {
        // Lookup the object by its object id
        let objectPointer = try ObjectFactory.lookupObjectPointer(
            oid: oid,
            type: GIT_OBJECT_ANY,
            repositoryPointer: repositoryPointer
        )
        defer { git_object_free(objectPointer) }

        let peeledPointer = try git {
            var pointer: OpaquePointer?
            // Perform the object peel operation
            let status = git_object_peel(&pointer, objectPointer, targetType)
            return (pointer, status)
        }

        // Create a pointer to the peeled object
        return peeledPointer
    }

    /// Creates a signature pointer from the given signature.
    ///
    /// - Parameter signature: The signature to create a pointer from.
    ///
    /// - Returns: A pointer to the signature.
    ///
    /// - Throws: `SignatureError.invalid` if the signature is invalid or an error occurs.
    ///
    /// - Important: The returned signature pointer must be released with `git_signature_free` when no longer needed.
    static func makeSignaturePointer(signature: Signature) throws(SwiftGitXError) -> UnsafeMutablePointer<git_signature>
    {
        let signaturePointer = try git {
            var pointer: UnsafeMutablePointer<git_signature>?
            // Perform the signature creation operation
            let status = git_signature_new(
                &pointer,
                signature.name,
                signature.email,
                git_time_t(signature.date.timeIntervalSince1970),
                Int32(signature.timezone.secondsFromGMT() / 60)
            )
            return (pointer, status)
        }

        return signaturePointer
    }
}
