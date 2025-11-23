import libgit2

public struct RemoteIterator: IteratorProtocol {
    private let remoteNames: [String]
    private let repositoryPointer: OpaquePointer

    init(remoteNames: [String], repositoryPointer: OpaquePointer) {
        self.remoteNames = remoteNames
        self.repositoryPointer = repositoryPointer
    }

    private var index = 0

    public mutating func next() -> Remote? {
        while true {
            // Task should not be cancelled
            if Task.isCancelled { return nil }

            // Check if the index is out of bounds
            guard index < remoteNames.count else { return nil }

            defer { index += 1 }

            // Get the remote name
            let name = remoteNames[index]

            // Try to get the remote pointer
            guard
                let remotePointer = try? ReferenceFactory.lookupRemotePointer(
                    name: name,
                    repositoryPointer: repositoryPointer
                )
            else { continue }
            defer { git_remote_free(remotePointer) }

            // Try to create a remote from the pointer
            // If the remote is not valid, continue to the next iteration
            if let remote = try? Remote(pointer: remotePointer) {
                return remote
            } else {
                continue
            }
        }
    }
}
