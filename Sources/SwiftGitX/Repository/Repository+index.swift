//
//  Repository+index.swift
//  SwiftGitX
//
//  Created by İbrahim Çetin on 23.11.2025.
//

import Foundation

extension Repository {
    /// Adds a file to the index.
    ///
    /// - Parameter path: The file path relative to the repository root directory.
    ///
    /// The path should be relative to the repository root directory.
    /// For example, `README.md` or `Sources/SwiftGitX/Repository.swift`.
    public func add(path: String) throws(SwiftGitXError) {
        try index.add(path: path)
    }

    /// Adds a file to the index.
    ///
    /// - Parameter file: The file URL.
    public func add(file: URL) throws(SwiftGitXError) {
        try index.add(file: file)
    }

    /// Adds files to the index.
    ///
    /// - Parameter paths: The paths of the files to add.
    ///
    /// The paths should be relative to the repository root directory.
    /// For example, `README.md` or `Sources/SwiftGitX/Repository.swift`.
    public func add(paths: [String]) throws(SwiftGitXError) {
        try index.add(paths: paths)
    }

    /// Adds files to the index.
    ///
    /// - Parameter files: The file URLs to add.
    public func add(files: [URL]) throws(SwiftGitXError) {
        try index.add(files: files)
    }

    // TODO: Investigate these methods

    internal func remove(path: String) throws(SwiftGitXError) {
        try index.remove(path: path)
    }

    internal func remove(file: URL) throws(SwiftGitXError) {
        try index.remove(file: file)
    }

    internal func remove(paths: [String]) throws(SwiftGitXError) {
        try index.remove(paths: paths)
    }

    internal func remove(files: [URL]) throws(SwiftGitXError) {
        try index.remove(files: files)
    }

    internal func removeAll() throws(SwiftGitXError) {
        try index.removeAll()
    }
}
