//
//  Commit.swift
//  SwiftGitX
//
//  Created by İbrahim Çetin on 24.11.2025.
//

import Foundation
import libgit2

/// A commit object representation in the repository.
public struct Commit: Object {
    /// The id of the commit.
    public let id: OID

    /// The author of the commit.
    public let author: Signature

    /// The committer of the commit.
    public let committer: Signature

    /// The message of the commit.
    public let message: String

    /// The first paragraph of the message.
    public let summary: String

    /// The message of the commit, excluding the first paragraph.
    public let body: String?

    /// The date of the commit.
    public let date: Date

    /// The tree of the commit.
    public let tree: Tree

    /// The parent commits of the commit.
    public var parents: [Commit] {
        get throws(SwiftGitXError) {
            // Lookup the commit
            let pointer = try ObjectFactory.lookupObjectPointer(
                oid: id.raw,
                type: GIT_OBJECT_COMMIT,
                repositoryPointer: repositoryPointer
            )
            defer { git_commit_free(pointer) }

            // Get the parent commits
            var parents = [Commit]()
            let parentCount = git_commit_parentcount(pointer)

            for index in 0..<parentCount {
                let parentPointer = try git {
                    var parentPointer: OpaquePointer?
                    let status = git_commit_parent(&parentPointer, pointer, index)
                    return (parentPointer, status)
                }
                defer { git_commit_free(parentPointer) }

                let parent = try Commit(pointer: parentPointer)
                parents.append(parent)
            }

            return parents
        }
    }

    /// The type of the object.
    public let type: ObjectType = .commit

    // This is necessary to get parents of the commit.
    private let repositoryPointer: OpaquePointer

    init(pointer: OpaquePointer) throws(SwiftGitXError) {
        let id = git_commit_id(pointer)?.pointee
        let author = git_commit_author(pointer)
        let committer = git_commit_committer(pointer)
        let message = git_commit_message(pointer)
        let body = git_commit_body(pointer)
        let summary = git_commit_summary(pointer)
        let date = git_commit_time(pointer)
        let repositoryPointer = git_commit_owner(pointer)

        let tree = try git {
            var tree: OpaquePointer?
            let status = git_commit_tree(&tree, pointer)
            return (tree, status)
        }
        defer { git_tree_free(tree) }

        guard let id,
            let author = author?.pointee,
            let committer = committer?.pointee,
            let message, let summary,
            let repositoryPointer
        else {
            throw SwiftGitXError(code: .error, category: .object, message: "Invalid commit")
        }

        self.id = OID(raw: id)
        self.author = Signature(raw: author)
        self.committer = Signature(raw: committer)
        self.message = String(cString: message)
        self.body = if let body { String(cString: body) } else { nil }
        self.summary = String(cString: summary)
        self.date = Date(timeIntervalSince1970: TimeInterval(date))
        self.tree = try Tree(pointer: tree)

        self.repositoryPointer = repositoryPointer
    }
}

extension Commit {
    // To ignore repositoryPointer
    public static func == (lhs: Commit, rhs: Commit) -> Bool {
        lhs.id == rhs.id
            && lhs.author == rhs.author
            && lhs.committer == rhs.committer
            && lhs.message == rhs.message
            && lhs.summary == rhs.summary
            && lhs.body == rhs.body
            && lhs.date == rhs.date
            && lhs.tree == rhs.tree
    }
}
