//
//  IndexCollection.swift
//  SwiftGitX
//
//  Created by İbrahim Çetin on 23.11.2025.
//

import Foundation
import libgit2

/// A collection of index operations.
struct IndexCollection {
    private let repositoryPointer: OpaquePointer

    init(repositoryPointer: OpaquePointer) {
        self.repositoryPointer = repositoryPointer
    }

    /// Reads the index from the repository.
    ///
    /// - Returns: The index pointer.
    ///
    /// The returned index pointer must be freed using `git_index_free`.
    private func readIndexPointer() throws(SwiftGitXError) -> OpaquePointer {
        try git(operation: .index) {
            var indexPointer: OpaquePointer?
            let status = git_repository_index(&indexPointer, repositoryPointer)
            return (indexPointer, status)
        }
    }

    /// Writes the index back to the repository.
    ///
    /// - Parameter indexPointer: The index pointer.
    private func writeIndex(indexPointer: OpaquePointer) throws(SwiftGitXError) {
        try git(operation: .index) {
            git_index_write(indexPointer)
        }
    }

    /// Returns the repository working directory relative path for a file.
    ///
    /// - Parameter file: The file URL.
    private func relativePath(for file: URL) throws(SwiftGitXError) -> String {
        guard let rawWorkingDirectory = git_repository_workdir(repositoryPointer) else {
            throw SwiftGitXError(code: .error, category: .repository, message: "Failed to get working directory")
        }

        let workingDirectory = URL(fileURLWithPath: String(cString: rawWorkingDirectory), isDirectory: true)

        return try file.relativePath(from: workingDirectory)
    }

    /// Adds a file to the index.
    ///
    /// - Parameter path: The file path relative to the repository root directory.
    ///
    /// The path should be relative to the repository root directory.
    /// For example, `README.md` or `Sources/SwiftGitX/Repository.swift`.
    func add(path: String) throws(SwiftGitXError) {
        // Read the index
        let indexPointer = try readIndexPointer()
        defer { git_index_free(indexPointer) }

        // Add the file to the index
        try git(operation: .index) {
            git_index_add_bypath(indexPointer, path)
        }

        // Write the index back to the repository
        try writeIndex(indexPointer: indexPointer)
    }

    /// Adds a file to the index.
    ///
    /// - Parameter file: The file URL.
    ///
    /// The file should be a URL to a file in the repository.
    func add(file: URL) throws(SwiftGitXError) {
        // Get the relative path of the file
        let relativePath = try relativePath(for: file)

        // Add the file to the index
        try add(path: relativePath)
    }

    /// Adds files to the index.
    ///
    /// - Parameter paths: The file paths relative to the repository root directory.
    ///
    /// The paths should be relative to the repository root directory.
    /// For example, `README.md` or `Sources/SwiftGitX/Repository.swift`.
    func add(paths: [String]) throws(SwiftGitXError) {
        // Read the index
        let indexPointer = try readIndexPointer()
        defer { git_index_free(indexPointer) }

        var strArray = paths.gitStrArray
        defer { git_strarray_free(&strArray) }

        let flags = GIT_INDEX_ADD_DEFAULT.rawValue | GIT_INDEX_ADD_DISABLE_PATHSPEC_MATCH.rawValue

        // TODO: Implement options
        // Add the files to the index
        try git(operation: .index) {
            git_index_add_all(indexPointer, &strArray, flags, nil, nil)
        }

        // Write the index back to the repository
        try writeIndex(indexPointer: indexPointer)
    }

    /// Adds files to the index.
    ///
    /// - Parameter files: The file URLs.
    ///
    /// The files should be URLs to files in the repository.
    func add(files: [URL]) throws(SwiftGitXError) {
        // Get the relative paths of the files
        let paths = try files.map { (url) throws(SwiftGitXError) -> String in
            try relativePath(for: url)
        }

        // Add the files to the index
        try add(paths: paths)
    }

    /// Removes a file from the index.
    ///
    /// - Parameter path: The file path relative to the repository root directory.
    ///
    /// The path should be relative to the repository root directory.
    /// For example, `README.md` or `Sources/SwiftGitX/Repository.swift`.
    func remove(path: String) throws(SwiftGitXError) {
        // Read the index
        let indexPointer = try readIndexPointer()
        defer { git_index_free(indexPointer) }

        // Remove the file from the index
        try git(operation: .index) {
            git_index_remove_bypath(indexPointer, path)
        }

        // Write the index back to the repository
        try writeIndex(indexPointer: indexPointer)
    }

    /// Removes a file from the index.
    ///
    /// - Parameter file: The file URL.
    ///
    /// The file should be a URL to a file in the repository.
    func remove(file: URL) throws(SwiftGitXError) {
        // Get the relative path of the file
        let relativePath = try relativePath(for: file)

        // Remove the file from the index
        try remove(path: relativePath)
    }

    /// Removes files from the index.
    ///
    /// - Parameter paths: The file paths relative to the repository root directory.
    ///
    /// The paths should be relative to the repository root directory.
    /// For example, `README.md` or `Sources/SwiftGitX/Repository.swift`.
    func remove(paths: [String]) throws(SwiftGitXError) {
        // Read the index
        let indexPointer = try readIndexPointer()
        defer { git_index_free(indexPointer) }

        // TODO: Implement options
        // Remove the files from the index
        var strArray = paths.gitStrArray
        defer { git_strarray_free(&strArray) }

        try git(operation: .index) {
            git_index_remove_all(indexPointer, &strArray, nil, nil)
        }

        // Write the index back to the repository
        try writeIndex(indexPointer: indexPointer)
    }

    /// Removes files from the index.
    ///
    /// - Parameter files: The file URLs.
    ///
    /// The files should be URLs to files in the repository.
    func remove(files: [URL]) throws(SwiftGitXError) {
        // Get the relative paths of the files
        let paths = try files.map { (url) throws(SwiftGitXError) -> String in
            try relativePath(for: url)
        }

        // Remove the files from the index
        try remove(paths: paths)
    }

    /// Removes all files from the index.
    ///
    /// This method will clear the index.
    func removeAll() throws(SwiftGitXError) {
        // Read the index
        let indexPointer = try readIndexPointer()
        defer { git_index_free(indexPointer) }

        // Remove all files from the index
        try git(operation: .index) {
            git_index_clear(indexPointer)
        }

        // Write the index back to the repository
        try writeIndex(indexPointer: indexPointer)
    }
}
