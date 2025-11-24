//
//  Blob.swift
//  SwiftGitX
//
//  Created by İbrahim Çetin on 24.11.2025.
//

import Foundation
import libgit2

/// A blob object representation in the repository.
///
/// A blob object is a binary large object that stores the content of a file.
public struct Blob: Object {
    /// The id of the blob.
    public let id: OID

    /// The content of the blob.
    public let content: Data

    /// The type of the object.
    public let type: ObjectType = .blob

    init(pointer: OpaquePointer) throws(SwiftGitXError) {
        let id = git_blob_id(pointer).pointee

        // ? Should we make it a computed property?
        let content = git_blob_rawcontent(pointer)

        guard let content else {
            throw SwiftGitXError(code: .error, category: .object, message: "Blob content is nil")
        }

        self.id = OID(raw: id)
        self.content = Data(bytes: content, count: Int(git_blob_rawsize(pointer)))
    }
}
