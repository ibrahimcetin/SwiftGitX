//
//  Repository+HEAD.swift
//  SwiftGitX
//
//  Created by İbrahim Çetin on 23.11.2025.
//

import libgit2

extension Repository {
    /// The HEAD reference of the repository.
    ///
    /// The HEAD is unborn if the repository has no commits. In this case, an error is thrown.
    /// If you want to get the name of the unborn HEAD, use the `config.defaultBranchName` property.
    ///
    /// The HEAD is detached if it points directly to a commit instead of a branch.
    ///
    /// - SeeAlso: If you curious about how HEAD works in Git, you can read Julia Evans's blog posts:
    ///     [How HEAD works in Git](https://jvns.ca/blog/2024/03/08/how-head-works-in-git/)
    ///     and
    ///     [The current branch in Git](https://jvns.ca/blog/2024/03/22/the-current-branch-in-git/)
    public var HEAD: any Reference {
        get throws(SwiftGitXError) {
            let referencePointer = try git(operation: .head) {
                var referencePointer: OpaquePointer?
                // Get the HEAD reference
                let status = git_repository_head(&referencePointer, pointer)
                return (referencePointer, status)
            }
            defer { git_reference_free(referencePointer) }

            if git_repository_head_detached(pointer) == 1 {
                // ? Should we create a type for detached HEAD named DetachedHEAD or something similar?
                // ? name: commit abbrev id, fullName: commit id, target: commit?

                // Detached HEAD is a branch reference pointing to a commit, it is name and fullName is "HEAD"
                let detachedHEAD = try Branch(pointer: referencePointer)

                // ? Should we use git describe to get the tag name?
                // Lookup if the detached HEAD is a tag reference
                for tag in self.tag where tag.target.id == detachedHEAD.target.id {
                    // If the tag is found, return the tag
                    return tag
                }

                // If the tag is not found, return the detached HEAD
                return detachedHEAD
            } else {
                return try Branch(pointer: referencePointer)
            }
        }
    }
}
