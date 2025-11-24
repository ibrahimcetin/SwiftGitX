//
//  Repository+show.swift
//  SwiftGitX
//
//  Created by İbrahim Çetin on 23.11.2025.
//

extension Repository {
    /// Lookups an object in the repository by its ID.
    ///
    /// - Parameter id: The ID of the object.
    ///
    /// - Returns: The object with the specified ID.
    ///
    /// - Throws: `ObjectError.invalid` if the object is not found or an error occurs.
    ///
    /// The type of the object must be specified when calling this method.
    ///
    /// Look up a commit by its ID
    /// ```swift
    /// let commit: Commit = try repository.show(id: commitID)
    /// ```
    ///
    /// Look up a tag by its ID
    /// ```swift
    /// let tag: Tag = try repository.show(id: treeID)
    /// ```
    public func show<ObjectType: Object>(id: OID) throws(SwiftGitXError) -> ObjectType {
        try ObjectFactory.lookupObject(oid: id.raw, repositoryPointer: pointer) as ObjectType
    }
}
