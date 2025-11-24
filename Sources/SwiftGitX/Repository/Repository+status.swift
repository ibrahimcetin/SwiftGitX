//
//  Repository+status.swift
//  SwiftGitX
//
//  Created by İbrahim Çetin on 23.11.2025.
//

import Foundation
import libgit2

extension Repository {
    /// Get the status of the repository.
    ///
    /// - Parameter options: The status options. Default is `.includeUntracked`.
    ///
    /// - Returns: The status of the repository.
    ///
    /// The status of the repository is represented by an array of `StatusEntry` values.
    public func status(options optionFlags: StatusOption = .default) throws(SwiftGitXError) -> [StatusEntry] {
        // Initialize the status options
        var statusOptions = git_status_options()
        try git(operation: .status) {
            git_status_options_init(&statusOptions, UInt32(GIT_STATUS_OPTIONS_VERSION))
        }

        // Set the status options
        statusOptions.flags = optionFlags.rawValue

        // Get the status list
        let statusListPointer = try git(operation: .status) {
            var statusListPointer: OpaquePointer?
            let statusListInitStatus = git_status_list_new(&statusListPointer, pointer, &statusOptions)
            return (statusListPointer, statusListInitStatus)
        }
        defer { git_status_list_free(statusListPointer) }

        // Get the status count
        let statusCount = git_status_list_entrycount(statusListPointer)

        // Create an array to store the status entries
        var statusEntries: [StatusEntry] = []

        // Iterate over the status entries
        for index in 0..<statusCount {
            // Get the status entry
            let statusEntryPointer = git_status_byindex(statusListPointer, index)

            // ? Should we handle the status entry differently if it's nil?
            guard let statusEntryPointer else {
                throw SwiftGitXError(
                    code: .notFound, category: .invalid,
                    message: "Failed to get the status entry at index \(index)"
                )
            }

            // Create a StatusEntry instance from the status entry
            let statusEntry = StatusEntry(raw: statusEntryPointer.pointee)

            // Append the status entry to the status entries array
            statusEntries.append(statusEntry)
        }

        return statusEntries
    }

    /// Get the status of the specified path.
    ///
    /// - Parameter path: The path of the file.
    ///
    /// - Returns: The status of the file.
    ///
    /// The path should be relative to the repository root directory. For example, `README.md` or
    /// `Sources/SwiftGitX/Repository.swift`.
    ///
    /// The status of the file is represented by an array of `StatusEntry.Status` values.
    /// Because a file can have multiple statuses. For example, a file can be both
    /// ``SwiftGitX/StatusEntry/Status-swift.enum/indexNew`` and
    /// ``SwiftGitX/StatusEntry/Status-swift.enum/workingTreeModified``.
    public func status(path: String) throws(SwiftGitXError) -> [StatusEntry.Status] {
        var statusFlags: UInt32 = 0

        try git(operation: .status) {
            git_status_file(&statusFlags, pointer, path)
        }

        return StatusEntry.Status.from(statusFlags)
    }

    /// Get the status of the specified file.
    ///
    /// - Parameter file: The file URL.
    ///
    /// - Returns: The status of the file.
    ///
    /// The status of the file is represented by an array of `StatusEntry.Status` values.
    /// Because a file can have multiple statuses. For example, a file can be both
    /// ``SwiftGitX/StatusEntry/Status-swift.enum/indexNew`` and
    /// ``SwiftGitX/StatusEntry/Status-swift.enum/workingTreeModified``.
    public func status(file: URL) throws(SwiftGitXError) -> [StatusEntry.Status] {
        let path = try file.relativePath(from: workingDirectory)
        return try status(path: path)
    }
}
