import Foundation
import libgit2

public enum RemoteCollectionError: Error, Equatable {
    case failedToList(String)
    case failedToAdd(String)
    case failedToRemove(String)
    case remoteAlreadyExists(String)
}

/// A collection of remotes and their operations.
public struct RemoteCollection: Sequence {
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

    // * I am not sure calling `git_error_last()` from a computed property is safe.
    // * Because libgit2 docs say that "The error message is thread-local. The git_error_last() call must happen on the
    // * same thread as the error in order to get the message."
    // * But, I think it is worth a try.
    private var errorMessage: String {
        String(cString: git_error_last().pointee.message)
    }

    /// Retrieves a remote by its name.
    ///
    /// - Parameter name: The name of the remote.
    ///
    /// - Returns: The remote with the specified name, or `nil` if it doesn't exist.
    public subscript(name: String) -> Remote? {
        try? get(named: name)
    }

    /// Returns a remote by name.
    ///
    /// - Parameter name: The name of the remote.
    ///
    /// - Returns: The remote with the specified name.
    public func get(named name: String) throws -> Remote {
        let remotePointer = try ReferenceFactory.lookupRemotePointer(name: name, repositoryPointer: repositoryPointer)
        defer { git_remote_free(remotePointer) }

        return try Remote(pointer: remotePointer)
    }

    /// Returns a list of remotes.
    ///
    /// - Returns: An array of remotes.
    ///
    /// - Throws: `RemoteCollectionError.failedToList` if the remotes could not be listed.
    ///
    /// If you want to iterate over the remotes, you can use the `makeIterator()` method.
    /// Iterator continues to the next remote even if an error occurs while getting the remote.
    public func list() throws -> [Remote] {
        let remotes = try remoteNames.map { remoteName in
            try get(named: remoteName)
        }

        return remotes
    }

    /// Adds a new remote to the repository.
    ///
    /// - Parameters:
    ///   - name: The name of the remote.
    ///   - url: The URL of the remote.
    ///
    /// - Returns: The remote that was added.
    ///
    /// - Throws: `RemoteCollectionError.failedToAdd` if the remote could not be added.
    @discardableResult
    public func add(named name: String, at url: URL) throws -> Remote {
        var remotePointer: OpaquePointer?
        defer { git_remote_free(remotePointer) }

        // Create a new remote
        let status = git_remote_create(&remotePointer, repositoryPointer, name, url.absoluteString)

        guard let remotePointer, status == GIT_OK.rawValue else {
            switch status {
            case GIT_EEXISTS.rawValue:
                throw RemoteCollectionError.remoteAlreadyExists(errorMessage)
            default:
                throw RemoteCollectionError.failedToAdd(errorMessage)
            }
        }

        return try Remote(pointer: remotePointer)
    }

    /// Remove a remote from the repository.
    ///
    /// - Parameter remote: The remote to remove.
    ///
    /// - Throws: `RemoteCollectionError.failedToRemove` if the remote could not be removed.
    public func remove(_ remote: Remote) throws {
        let status = git_remote_delete(repositoryPointer, remote.name)

        guard status == GIT_OK.rawValue else {
            throw RemoteCollectionError.failedToRemove(errorMessage)
        }
    }

    public func makeIterator() -> RemoteIterator {
        RemoteIterator(remoteNames: (try? remoteNames) ?? [], repositoryPointer: repositoryPointer)
    }

    private var remoteNames: [String] {
        get throws {
            // Create a list to store the remote names
            var array = git_strarray()
            defer { git_strarray_free(&array) }

            // Get the remote names
            let status = git_remote_list(&array, repositoryPointer)

            guard status == GIT_OK.rawValue else {
                throw RemoteCollectionError.failedToList(errorMessage)
            }

            // Create a list to store the remote names
            var remoteNames = [String]()

            // Convert raw remote names to Swift strings
            for index in 0 ..< array.count {
                guard let rawRemoteName = array.strings.advanced(by: index).pointee
                else {
                    throw RemoteCollectionError.failedToList("Failed to get remote name at index \(index)")
                }

                let remoteName = String(cString: rawRemoteName)
                remoteNames.append(remoteName)
            }

            return remoteNames
        }
    }
}
