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
            try initializeRuntimeIfNeeded()
            defer { try? shutdownRuntimeIfNeeded() }

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
    @available(*, deprecated, message: "Use set(_:to:) instead. Be careful, parameter order is reversed.")
    public func set(_ string: String, forKey key: String) throws(SwiftGitXError) {
        try self.set(key, to: string)
    }

    /// Sets a configuration value for the repository.
    ///
    /// - Parameters:
    ///   - key: The key to set the value for.
    ///   - value: The value to set.
    ///
    /// This will set the configuration value for the repository, if a repository instance is provided.
    /// Otherwise, it will set the global configuration value.
    ///
    /// ### Example
    ///
    /// ```swift
    /// // Set repository-specific configuration values
    /// try repository.config.set("user.name", to: "John Doe")
    /// try repository.config.set("user.email", to: "john.doe@example.com")
    /// ```
    ///
    /// ```swift
    /// // Set global configuration values
    /// try Repository.config.set("user.name", to: "John Doe")
    /// try Repository.config.set("user.email", to: "john.doe@example.com")
    /// ```
    public func set(_ key: String, to value: String) throws(SwiftGitXError) {
        try initializeRuntimeIfNeeded()
        defer { try? shutdownRuntimeIfNeeded() }

        let configPointer = try self.configPointer()
        defer { git_config_free(configPointer) }

        try git(operation: .config) {
            git_config_set_string(configPointer, key, value)
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
        try initializeRuntimeIfNeeded()
        defer { try? shutdownRuntimeIfNeeded() }

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
        return try git(operation: .config) {
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

    /// Initializes the SwiftGitXRuntime if needed.
    ///
    /// While managing global configurations, the runtime may not have been initialized yet.
    private func initializeRuntimeIfNeeded() throws(SwiftGitXError) {
        if repositoryPointer == nil {
            try SwiftGitXRuntime.initialize()
        }
    }

    private func shutdownRuntimeIfNeeded() throws(SwiftGitXError) {
        if repositoryPointer == nil {
            try SwiftGitXRuntime.shutdown()
        }
    }
}
