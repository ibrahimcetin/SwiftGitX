import Foundation
import libgit2

/// An error that occurred while performing an index operation.
public enum IndexError: Error {
    /// An error occurred while reading the index from the repository.
    case failedToReadIndex(String)

    /// An error occurred while writing the index back to the repository.
    case failedToWriteIndex(String)

    /// An error occurred while adding a file to the index.
    case failedToAddFile(String)

    /// An error occurred while removing a file from the index.
    case failedToRemoveFile(String)
}

/// A collection of index operations.
struct IndexCollection {
    private var repositoryPointer: OpaquePointer {
        get {
            repositoryPointerProtector.read { $0 }
        }
        set {
            repositoryPointerProtector.write(newValue)
        }
    }

    private let repositoryPointerProtector: Protected<OpaquePointer>

    init(repositoryPointer: OpaquePointer) {
        self.repositoryPointerProtector = Protected(repositoryPointer)
    }

    /// The error message from the last failed operation.
    private var errorMessage: String {
        String(cString: git_error_last().pointee.message)
    }

    /// Reads the index from the repository.
    ///
    /// - Returns: The index pointer.
    ///
    /// The returned index pointer must be freed using `git_index_free`.
    private func readIndexPointer() throws -> OpaquePointer {
        var indexPointer: OpaquePointer?
        let status = git_repository_index(&indexPointer, repositoryPointer)

        guard let indexPointer, status == GIT_OK.rawValue else {
            throw IndexError.failedToReadIndex(errorMessage)
        }

        return indexPointer
    }

    /// Writes the index back to the repository.
    ///
    /// - Parameter indexPointer: The index pointer.
    private func writeIndex(indexPointer: OpaquePointer) throws {
        let status = git_index_write(indexPointer)

        guard status == GIT_OK.rawValue else {
            throw IndexError.failedToWriteIndex(errorMessage)
        }
    }

    /// Returns the repository working directory relative path for a file.
    ///
    /// - Parameter file: The file URL.
    private func relativePath(for file: URL) throws -> String {
        guard let rawWorkingDirectory = git_repository_workdir(repositoryPointer) else {
            throw RepositoryError.failedToGetWorkingDirectory
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
    func add(path: String) throws {
        // Read the index
        let indexPointer = try readIndexPointer()
        defer { git_index_free(indexPointer) }

        // Add the file to the index
        let status = git_index_add_bypath(indexPointer, path)

        guard status == GIT_OK.rawValue else {
            throw IndexError.failedToAddFile(errorMessage)
        }

        // Write the index back to the repository
        try writeIndex(indexPointer: indexPointer)
    }

    /// Adds a file to the index.
    ///
    /// - Parameter file: The file URL.
    ///
    /// The file should be a URL to a file in the repository.
    func add(file: URL) throws {
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
    func add(paths: [String]) throws {
        // Read the index
        let indexPointer = try readIndexPointer()
        defer { git_index_free(indexPointer) }

        try paths.withGitStrArray { strArray in
            var strArray = strArray

            let flags = GIT_INDEX_ADD_DEFAULT.rawValue | GIT_INDEX_ADD_DISABLE_PATHSPEC_MATCH.rawValue

            // TODO: Implement options
            // Add the files to the index
            let status = git_index_add_all(indexPointer, &strArray, flags, nil, nil)

            guard status == GIT_OK.rawValue else {
                throw IndexError.failedToAddFile(errorMessage)
            }
        }
        // Write the index back to the repository
        try writeIndex(indexPointer: indexPointer)
    }

    /// Adds files to the index.
    ///
    /// - Parameter files: The file URLs.
    ///
    /// The files should be URLs to files in the repository.
    func add(files: [URL]) throws {
        // Get the relative paths of the files
        let paths = try files.map { try relativePath(for: $0) }

        // Add the files to the index
        try add(paths: paths)
    }

    /// Removes a file from the index.
    ///
    /// - Parameter path: The file path relative to the repository root directory.
    ///
    /// The path should be relative to the repository root directory.
    /// For example, `README.md` or `Sources/SwiftGitX/Repository.swift`.
    func remove(path: String) throws {
        // Read the index
        let indexPointer = try readIndexPointer()
        defer { git_index_free(indexPointer) }

        // Remove the file from the index
        let status = git_index_remove_bypath(indexPointer, path)

        guard status == GIT_OK.rawValue else {
            throw IndexError.failedToRemoveFile(errorMessage)
        }

        // Write the index back to the repository
        try writeIndex(indexPointer: indexPointer)
    }

    /// Removes a file from the index.
    ///
    /// - Parameter file: The file URL.
    ///
    /// The file should be a URL to a file in the repository.
    func remove(file: URL) throws {
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
    func remove(paths: [String]) throws {
        // Read the index
        let indexPointer = try readIndexPointer()
        defer { git_index_free(indexPointer) }

        // TODO: Implement options
        // Remove the files from the index
        try paths.withGitStrArray { strArray in
            var strArray = strArray
            let status = git_index_remove_all(indexPointer, &strArray, nil, nil)

            guard status == GIT_OK.rawValue else {
                throw IndexError.failedToRemoveFile(errorMessage)
            }
        }

        // Write the index back to the repository
        try writeIndex(indexPointer: indexPointer)
    }

    /// Removes files from the index.
    ///
    /// - Parameter files: The file URLs.
    ///
    /// The files should be URLs to files in the repository.
    func remove(files: [URL]) throws {
        // Get the relative paths of the files
        let paths = try files.map { try relativePath(for: $0) }

        // Remove the files from the index
        try remove(paths: paths)
    }

    /// Removes all files from the index.
    ///
    /// This method will clear the index.
    func removeAll() throws {
        // Read the index
        let indexPointer = try readIndexPointer()
        defer { git_index_free(indexPointer) }

        // Remove all files from the index
        let status = git_index_clear(indexPointer)

        guard status == GIT_OK.rawValue else {
            throw IndexError.failedToRemoveFile(errorMessage)
        }

        // Write the index back to the repository
        try writeIndex(indexPointer: indexPointer)
    }
}
