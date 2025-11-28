//
//  Remote.swift
//  SwiftGitX
//
//  Created by İbrahim Çetin on 24.11.2025.
//

import Foundation
import libgit2

/// A remote representation in the repository.
public struct Remote: Equatable, Hashable, Sendable {
    /// The name of the remote.
    public let name: String

    /// The URL of the remote.
    public let url: URL

    /// The branches of the remote which are available in the repository.
    public var branches: [Branch] {
        let branchSequence = BranchSequence(type: .remote, repositoryPointer: repositoryPointer)
        return branchSequence.filter {
            $0.fullName.hasPrefix("\(GitDirectoryConstants.remotes)\(name)/")
        }
    }

    /// The opaque pointer to the repository.
    nonisolated(unsafe) private let repositoryPointer: OpaquePointer

    /// Initializes a `Remote` instance with the given opaque pointer.
    ///
    /// - Parameter pointer: The opaque pointer representing the remote.
    /// - Throws: A `RemoteError` if the remote is invalid or if the URLs are invalid.
    init(pointer: OpaquePointer) throws(SwiftGitXError) {
        // Get the remote name, URL, and push URL
        let name = git_remote_name(pointer)
        let url = git_remote_url(pointer)

        let repositoryPointer = git_remote_owner(pointer)

        // Check if the remote name and url pointers are valid
        guard let name, let url, let repositoryPointer else {
            throw SwiftGitXError(code: .error, category: .reference, message: "Remote is invalid")
        }

        // Set the name
        self.name = String(cString: name)

        // Check if the URL is valid
        guard let url = URL(string: String(cString: url)) else {
            throw SwiftGitXError(code: .error, category: .reference, message: "Invalid remote URL")
        }

        self.url = url

        self.repositoryPointer = repositoryPointer
    }
}

// MARK: - Remote Extension

extension Remote {
    public static func == (lhs: Remote, rhs: Remote) -> Bool {
        lhs.name == rhs.name && lhs.url == rhs.url
    }
}
