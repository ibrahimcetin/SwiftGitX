import libgit2

public enum TagCollectionError: Error {
    case failedToList(String)
    case failedToCreate(String)
}

/// A collection of tags and their operations.
public struct TagCollection: Sequence {
    private var repositoryPointer: OpaquePointer

    init(repositoryPointer: OpaquePointer) {
        self.repositoryPointer = repositoryPointer
    }

    // * I am not sure calling `git_error_last()` from a computed property is safe.
    // * Because libgit2 docs say that "The error message is thread-local. The git_error_last() call must happen on the
    // * same thread as the error in order to get the message."
    // * But, I think it is worth a try.
    private var errorMessage: String {
        String(cString: git_error_last().pointee.message)
    }

    public subscript(name: String) -> Tag? {
        try? get(named: name)
    }

    public func get(named name: String) throws -> Tag {
        try ObjectFactory.lookupTag(name: name, repositoryPointer: repositoryPointer)
    }

    // TODO: Maybe we can write it as TagIterator
    public func list() throws -> [Tag] {
        var array = git_strarray()
        defer { git_strarray_free(&array) }

        let status = git_tag_list(&array, repositoryPointer)

        guard status == GIT_OK.rawValue else {
            throw TagCollectionError.failedToList(errorMessage)
        }

        var tags = [Tag]()
        for index in 0..<array.count {
            let tagName = String(cString: array.strings.advanced(by: index).pointee!)

            let tag = try get(named: tagName)
            tags.append(tag)
        }

        return tags
    }

    /// Creates a new tag.
    ///
    /// - Parameters:
    ///   - name: The name of the tag.
    ///   - target: The target object for the tag.
    ///   - type: The type of the tag. Default is `.annotated`.
    ///   - tagger: The signature of the tagger. If not provided, the default signature in the repository will be used.
    ///   - message: The message associated with the tag. If not provided, an empty string will be used.
    ///   - force: If `true`, the tag will be overwritten if it already exists. Default is `false`.
    ///
    /// - Returns: The created `Tag` object.
    ///
    /// - Throws: `TagCollectionError.failedToCreate` if the tag could not be created.
    ///
    /// - Note: If the tag already exists and `force` is `false`, an error will be thrown.
    @discardableResult
    public func create(
        named name: String,
        target: any Object,
        type: TagType = .annotated,
        tagger: Signature? = nil,
        message: String? = nil,
        force: Bool = false
    ) throws -> Tag {
        let targetPointer = try ObjectFactory.lookupObjectPointer(
            oid: target.id.raw,
            type: GIT_OBJECT_ANY,
            repositoryPointer: repositoryPointer
        )
        defer { git_object_free(targetPointer) }

        var tagID = git_oid()

        switch type {
        case .annotated:
            // Get the default signature if none is provided
            let tagger = try tagger ?? Signature.default(in: repositoryPointer)

            // Create a pointer to the tagger
            let taggerPointer = try ObjectFactory.makeSignaturePointer(signature: tagger)
            defer { git_signature_free(taggerPointer) }

            // Create an annotated tag
            let status = git_tag_create(
                &tagID,
                repositoryPointer,
                name,
                targetPointer,
                taggerPointer,
                message ?? "",
                force ? 1 : 0
            )

            guard status == GIT_OK.rawValue else {
                throw TagCollectionError.failedToCreate(errorMessage)
            }

        case .lightweight:
            // Create a lightweight tag
            let status = git_tag_create_lightweight(
                &tagID,
                repositoryPointer,
                name,
                targetPointer,
                force ? 1 : 0
            )

            guard status == GIT_OK.rawValue else {
                throw TagCollectionError.failedToCreate(errorMessage)
            }
        }

        // Lookup the tag by its name
        return try get(named: name)
    }

    public func makeIterator() -> TagIterator {
        TagIterator(repositoryPointer: repositoryPointer)
    }
}
