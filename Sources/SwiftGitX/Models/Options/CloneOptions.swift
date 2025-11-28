import libgit2

/// Options for the clone operation.
public struct CloneOptions: Sendable {
    public static let `default` = CloneOptions()

    public static let bare = CloneOptions(bare: true)

    /// If true, clone as a bare repository. Otherwise, clone as a normal repository. Default is false.
    public let bare: Bool

    public init(bare: Bool = false) {
        self.bare = bare
    }

    var gitCloneOptions: git_clone_options {
        var options = git_clone_options()
        git_clone_init_options(&options, UInt32(GIT_CLONE_OPTIONS_VERSION))

        options.bare = bare ? 1 : 0

        return options
    }
}
