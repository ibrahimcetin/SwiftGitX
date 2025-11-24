//
//  Repository+log.swift
//  SwiftGitX
//
//  Created by İbrahim Çetin on 23.11.2025.
//

extension Repository {
    /// Retrieves the commit history of the repository.
    ///
    /// - Parameter sorting: The sorting option for the commit history. Defaults to `.none`.
    ///
    /// - Returns: A `CommitSequence` representing the commit history.
    public func log(sorting: LogSortingOption = .none) throws(SwiftGitXError) -> CommitSequence {
        try log(from: HEAD, sorting: sorting)
    }

    /// Retrieves the commit history from the given reference.
    ///
    /// - Parameters:
    ///   - reference: The reference to start the commit history from.
    ///   - sorting: The option to sort the commit history. Default is `.none`.
    ///
    /// - Returns: A `CommitSequence` representing the commit history.
    public func log(
        from reference: any Reference,
        sorting: LogSortingOption = .none
    ) throws(SwiftGitXError) -> CommitSequence {
        if let commit = reference.target as? Commit {
            return log(from: commit, sorting: sorting)
        } else {
            throw SwiftGitXError(code: .invalid, category: .reference, message: "Reference target is not a commit")
        }
    }

    /// Retrieves the commit history from the specified commit.
    ///
    /// - Parameters:
    ///   - commit: The commit to start the commit history from.
    ///   - sorting: The sorting option for the commit sequence. Default is `.none`.
    ///
    /// - Returns: A `CommitSequence` representing the commit history.
    public func log(from commit: Commit, sorting: LogSortingOption = .none) -> CommitSequence {
        CommitSequence(root: commit, sorting: sorting, repositoryPointer: pointer)
    }
}
