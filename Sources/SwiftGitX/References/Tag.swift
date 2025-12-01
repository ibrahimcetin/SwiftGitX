//
//  Tag.swift
//  SwiftGitX
//
//  Created by İbrahim Çetin on 24.11.2025.
//

import Foundation
import libgit2

/// A tag representation in the repository.
public struct Tag: Object, Reference {
    /// The id of the tag.
    public let id: OID

    /// The target of the tag.
    public let target: any Object

    /// The name of the tag.
    ///
    /// For example, `v1.0.0`.
    public let name: String

    /// The full name of the tag.
    ///
    /// For example, `refs/tags/v1.0.0`.
    public let fullName: String

    /// The type of the reference.
    ///
    /// It is always `direct` for tags.
    public let referenceType: ReferenceType = .direct

    /// The tagger of the tag.
    ///
    /// If the tag is lightweight, the tagger will be `nil`.
    public let tagger: Signature?

    /// The message of the tag.
    public let message: String?

    /// The type of the object.
    public let type: ObjectType = .tag

    init(pointer: OpaquePointer) throws(SwiftGitXError) {
        // Get the id of the tag.
        let id = git_tag_id(pointer)

        // Get the target id of the tag.
        let targetID = git_tag_target_id(pointer)

        // Get the name of the tag.
        let name = git_tag_name(pointer)

        // Get the tagger of the tag.
        let tagger = git_tag_tagger(pointer)

        // Get the message of the tag.
        let message = git_tag_message(pointer)

        // Get the repository pointer.
        let repositoryPointer = git_tag_owner(pointer)

        guard let id = id?.pointee, let targetID = targetID?.pointee, let name, let repositoryPointer else {
            throw SwiftGitXError(code: .error, category: .object, message: "Tag is invalid")
        }

        // Set the id of the tag.
        self.id = OID(raw: id)

        // Set the target of the tag.
        target = try ObjectFactory.lookupObject(oid: targetID, repositoryPointer: repositoryPointer)

        // Set the name of the tag.
        self.name = String(cString: name)
        fullName = GitDirectoryConstants.tags + self.name

        // Set the tagger of the tag.
        self.tagger =
            if let tagger {
                Signature(pointer: tagger)
            } else { nil }

        // Set the message of the tag. If the message is empty, set it to `nil`.
        self.message =
            if let message, strcmp(message, "") != 0 {
                String(cString: message)
            } else { nil }
    }

    /// Lightweight tag initializer
    init(name: String, target: any Object) {
        id = target.id

        self.target = target

        self.name = name
        fullName = GitDirectoryConstants.tags + name

        tagger = nil
        message = nil
    }
}
