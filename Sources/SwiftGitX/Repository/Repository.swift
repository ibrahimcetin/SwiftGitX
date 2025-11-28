//
//  Repository.swift
//  SwiftGitX
//
//  Created by İbrahim Çetin on 10.03.2024.
//

import Foundation
import libgit2

/// A representation of a Git repository.
public final class Repository: Sendable {
    // TODO: Should we really use a locking mechanism here? What are the performance implications?
    /// The libgit2 pointer of the repository.
    nonisolated(unsafe) internal let pointer: OpaquePointer

    /// Initialize a new repository with the specified libgit2 pointer.
    internal init(pointer: OpaquePointer) {
        self.pointer = pointer
    }

    /// Open or create a repository at the specified path.
    ///
    /// - Parameters:
    ///   - path: The path to the repository.
    ///   - createIfNotExists: If `true`, create a new repository if there is no repository at the given path.
    /// Default is `true`.
    ///
    /// If a repository exists at the specified path, it will be opened.
    /// If a repository does not exist, a new one will be created.
    ///
    /// The `path` argument must point to either an existing working directory, or a `.git` repository folder to open.
    public init(at path: URL, createIfNotExists: Bool = true) throws(SwiftGitXError) {
        // Initialize the SwiftGitXRuntime
        try SwiftGitXRuntime.initialize()

        let pointerOpen = try? git(operation: .repositoryOpen) {
            var pointer: OpaquePointer?
            // Try to open the repository at the specified path
            let status = git_repository_open(&pointer, path.path)
            return (pointer, status)
        }

        if let pointerOpen {
            self.pointer = pointerOpen
        } else if createIfNotExists {
            // If the repository does not exist, create a new one
            let pointerCreate = try git(operation: .repositoryCreate) {
                var pointer: OpaquePointer?
                let status = git_repository_init(&pointer, path.path, 0)
                return (pointer, status)
            }

            self.pointer = pointerCreate
        } else {
            // Shutdown the SwiftGitXRuntime
            _ = try? SwiftGitXRuntime.shutdown()

            // If the repository does not exist and createIfNotExists is false, throw an error
            throw SwiftGitXError(
                code: .notFound, category: .repository,
                message: "Repository not found at \(path.path)"
            )
        }
    }

    deinit {
        // Free the repository pointer
        git_repository_free(pointer)

        // Shutdown the SwiftGitXRuntime
        _ = try? SwiftGitXRuntime.shutdown()
    }
}

extension Repository: Codable, Equatable, Hashable {
    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let path = try container.decode(String.self)

        try self.init(at: URL(fileURLWithPath: path), createIfNotExists: false)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(workingDirectory.path)
    }

    public static func == (lhs: Repository, rhs: Repository) -> Bool {
        lhs.path == rhs.path
    }

    public func hash(into hasher: inout Hasher) {
        // ? should we hash pointer?
        hasher.combine(path)
    }
}

// MARK: - Repository properties

extension Repository {
    /// The working directory of the repository.
    ///
    /// - Returns: The URL of the working directory.
    ///
    /// - Throws: `SwiftGitXError` if the repository is bare.
    public var workingDirectory: URL {
        get throws(SwiftGitXError) {
            guard let path = git_repository_workdir(pointer)
            else {
                throw SwiftGitXError(code: .error, category: .repository, message: "Failed to get working directory")
            }

            return URL(fileURLWithPath: String(cString: path), isDirectory: true, relativeTo: nil)
        }
    }

    /// The path of the repository.
    ///
    /// - Returns: The `.git` directory path. (e.g. /path/to/repo/.git)
    ///
    /// This is the path of the `.git` folder for normal repositories, or of the repository itself for `bare`
    /// repositories.
    ///
    /// - Note: Use ``workingDirectory`` to get the working directory path.
    public var path: URL {
        // ? Should we handle `nil` case?
        URL(fileURLWithPath: String(cString: git_repository_path(pointer)))
    }

    // TODO: add state property (git_repository_state)

    /// Check if the repository is empty.
    ///
    /// A repository is considered empty if it has no commits.
    public var isEmpty: Bool {
        // TODO: Throw an error if the return value is not 0 or 1
        git_repository_is_empty(pointer) == 1
    }

    /// Check if the repository is HEAD detached.
    ///
    /// A repository’s HEAD is detached when it points directly to a commit instead of a branch.
    public var isHEADDetached: Bool {
        git_repository_head_detached(pointer) == 1
    }

    /// Check if the repository is HEAD unborn.
    ///
    /// A repository is considered HEAD unborn if the HEAD reference is not yet initialized.
    public var isHEADUnborn: Bool {
        git_repository_head_unborn(pointer) == 1
    }

    /// Check if the repository is shallow.
    ///
    /// A repository is considered shallow if it has a limited history.
    public var isShallow: Bool {
        git_repository_is_shallow(pointer) == 1
    }

    /// Check if the repository is bare.
    public var isBare: Bool {
        git_repository_is_bare(pointer) == 1
    }
}

// MARK: - Repository factory methods

extension Repository {
    /// Open a repository at the specified path.
    ///
    /// - Parameter path: The path to the repository.
    ///
    /// - Returns: The repository at the specified path.
    public static func open(at path: URL) throws(SwiftGitXError) -> Repository {
        // Initialize the SwiftGitXRuntime
        try SwiftGitXRuntime.initialize()

        do {
            // Open the repository at the specified path
            let pointer = try git(operation: .repositoryOpen) {
                var pointer: OpaquePointer?
                let status = git_repository_open(&pointer, path.path)
                return (pointer, status)
            }

            return Repository(pointer: pointer)
        } catch {
            // Shutdown the SwiftGitXRuntime
            _ = try? SwiftGitXRuntime.shutdown()

            // Rethrow the error
            throw error
        }
    }

    /// Create a new repository at the specified path.
    ///
    /// - Parameters:
    ///   - path: The path to the repository.
    ///   - isBare: A boolean value that indicates whether the repository should be bare.
    ///
    /// - Returns: The repository at the specified path.
    public static func create(at path: URL, isBare: Bool = false) throws(SwiftGitXError) -> Repository {
        // Initialize the SwiftGitXRuntime
        try SwiftGitXRuntime.initialize()

        do {
            // Create a new repository at the specified URL
            let pointer = try git(operation: .repositoryCreate) {
                var pointer: OpaquePointer?
                let status = git_repository_init(&pointer, path.path, isBare ? 1 : 0)
                return (pointer, status)
            }

            return Repository(pointer: pointer)
        } catch {
            // Shutdown the SwiftGitXRuntime
            _ = try? SwiftGitXRuntime.shutdown()

            // Rethrow the error
            throw error
        }
    }
}

// MARK: - Collections

extension Repository {
    /// Collection of branch operations.
    public var branch: BranchCollection {
        BranchCollection(repositoryPointer: pointer)
    }

    /// Collection of repository configuration operations.
    public var config: ConfigCollection {
        ConfigCollection(repositoryPointer: pointer)
    }

    /// Collection of global configuration operations.
    public static var config: ConfigCollection {
        ConfigCollection()
    }

    /// Collection of index operations.
    internal var index: IndexCollection {
        IndexCollection(repositoryPointer: pointer)
    }

    /// Collection of reference operations.
    public var reference: ReferenceCollection {
        ReferenceCollection(repositoryPointer: pointer)
    }

    /// Collection of remote operations.
    public var remote: RemoteCollection {
        RemoteCollection(repositoryPointer: pointer)
    }

    /// Collection of stash operations.
    public var stash: StashCollection {
        StashCollection(repositoryPointer: pointer)
    }

    /// Collection of tag operations.
    public var tag: TagCollection {
        TagCollection(repositoryPointer: pointer)
    }
}

extension SwiftGitXError.Operation {
    static let repositoryCreate = Self(rawValue: "repositoryCreate")
    static let repositoryOpen = Self(rawValue: "repositoryOpen")
}
