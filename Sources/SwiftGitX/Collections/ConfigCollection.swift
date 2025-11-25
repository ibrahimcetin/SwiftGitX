//
//  ConfigCollection.swift
//  SwiftGitX
//
//  Created by İbrahim Çetin on 24.11.2025.
//

import libgit2

// ? Should we use actor?
/// A collection of configurations and their operations.
public struct ConfigCollection {
    private let repositoryPointer: OpaquePointer?

    /// Init for repository configurations.
    init(repositoryPointer: OpaquePointer) {
        self.repositoryPointer = repositoryPointer
    }

    /// Init for global configurations.
    init() {
        repositoryPointer = nil
    }

    /// The default branch name of the repository
    ///
    /// - Returns: The default branch name of the repository
    ///
    /// This is the branch that is checked out when the repository is initialized.
    public var defaultBranchName: String {
        get throws(SwiftGitXError) {
            let configPointer = try self.configPointer()
            defer { git_config_free(configPointer) }

            var branchNameBuffer = git_buf()
            defer { git_buf_free(&branchNameBuffer) }

            try git(operation: .config) {
                git_config_get_string_buf(&branchNameBuffer, configPointer, "init.defaultBranch")
            }

            return String(cString: branchNameBuffer.ptr)
        }
    }

    /// Sets a configuration value for the repository.
    ///
    /// - Parameters:
    ///   - string: The value to set.
    ///   - key: The key to set the value for.
    ///
    /// This will set the configuration value for the repository.
    public func set(_ string: String, forKey key: String) throws(SwiftGitXError) {
        let configPointer = try self.configPointer()
        defer { git_config_free(configPointer) }

        try git(operation: .config) {
            git_config_set_string(configPointer, key, string)
        }
    }

    /// Returns the configuration value for the repository.
    ///
    /// - Parameter key: The key to get the value for.
    ///
    /// - Returns: The configuration value for the key.
    ///
    /// All config files will be looked into, in the order of their defined level. A higher level means a higher
    /// priority. The first occurrence of the variable will be returned here.
    public func string(forKey key: String) throws(SwiftGitXError) -> String? {
        let configPointer = try self.configPointer()
        defer { git_config_free(configPointer) }

        var valueBuffer = git_buf()
        defer { git_buf_free(&valueBuffer) }

        try git(operation: .config) {
            git_config_get_string_buf(&valueBuffer, configPointer, key)
        }

        return String(cString: valueBuffer.ptr)
    }

    /// Returns a pointer to the git configuration object.
    ///
    /// - Returns: An `OpaquePointer` to the git configuration object.
    ///
    /// If a repository pointer is available, this method retrieves the repository-specific configuration.
    /// Otherwise, it opens the default global git configuration.
    ///
    /// - Important: The caller is responsible for freeing the returned pointer using `git_config_free()`.
    private func configPointer() throws(SwiftGitXError) -> OpaquePointer {
        try git(operation: .config) {
            var configPointer: OpaquePointer?
            let status =
                if let repositoryPointer {
                    git_repository_config(&configPointer, repositoryPointer)
                } else {
                    git_config_open_default(&configPointer)
                }
            return (configPointer, status)
        }
    }
}
