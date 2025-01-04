import libgit2

// ? Should we use actor?
/// A collection of configurations and their operations.
public struct ConfigCollection {
    private var repositoryPointer: OpaquePointer? {
        get {
            repositoryPointerProtector.read { $0 }
        }
        set {
            repositoryPointerProtector.write(newValue)
        }
    }

    private let repositoryPointerProtector: Protected<OpaquePointer?>

    /// Init for repository configurations.
    init(repositoryPointer: OpaquePointer) {
        self.repositoryPointerProtector = Protected(repositoryPointer)
    }

    /// Init for global configurations.
    init() {
        self.repositoryPointerProtector = Protected(nil)
    }

    /// The default branch name of the repository
    ///
    /// - Returns: The default branch name of the repository
    ///
    /// This is the branch that is checked out when the repository is initialized.
    public var defaultBranchName: String {
        var configPointer: OpaquePointer?
        defer { git_config_free(configPointer) }

        if let repositoryPointer {
            git_repository_config(&configPointer, repositoryPointer)
        } else {
            git_config_open_default(&configPointer)
        }

        var branchNameBuffer = git_buf()
        defer { git_buf_free(&branchNameBuffer) }

        git_config_get_string_buf(&branchNameBuffer, configPointer, "init.defaultBranch")

        return String(cString: branchNameBuffer.ptr)
    }

    /// Sets a configuration value for the repository.
    ///
    /// - Parameters:
    ///   - string: The value to set.
    ///   - key: The key to set the value for.
    ///
    /// This will set the configuration value for the repository.
    public func set(_ string: String, forKey key: String) {
        var configPointer: OpaquePointer?
        defer { git_config_free(configPointer) }

        if let repositoryPointer {
            git_repository_config(&configPointer, repositoryPointer)
        } else {
            git_config_open_default(&configPointer)
        }

        guard let configPointer else {
            // TODO: Handle error
            return
        }

        git_config_set_string(configPointer, key, string)
    }

    /// Returns the configuration value for the repository.
    ///
    /// - Parameter key: The key to get the value for.
    ///
    /// - Returns: The configuration value for the key.
    ///
    /// All config files will be looked into, in the order of their defined level. A higher level means a higher
    /// priority. The first occurrence of the variable will be returned here.
    public func string(forKey key: String) -> String? {
        var configPointer: OpaquePointer?
        defer { git_config_free(configPointer) }

        if let repositoryPointer {
            git_repository_config(&configPointer, repositoryPointer)
        } else {
            git_config_open_default(&configPointer)
        }

        guard let configPointer else {
            // TODO: Handle error
            return nil
        }

        var valueBuffer = git_buf()
        defer { git_buf_free(&valueBuffer) }

        let status = git_config_get_string_buf(&valueBuffer, configPointer, key)

        guard let pointer = valueBuffer.ptr, status == GIT_OK.rawValue else {
            return nil
        }

        return String(cString: pointer)
    }
}
