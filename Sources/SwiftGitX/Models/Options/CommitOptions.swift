import libgit2

/// Options for the commit operation.
public struct CommitOptions: Sendable {
    public static let `default` = CommitOptions()

    public static let allowEmpty = CommitOptions(allowEmpty: true)

    /// If true, allow creating a commit with no changes. Otherwise, fail if there are no changes. Default is false.
    public let allowEmpty: Bool

    public init(allowEmpty: Bool = false) {
        self.allowEmpty = allowEmpty
    }

    var gitCommitCreateOptions: git_commit_create_options {
        var options = git_commit_create_options()
        options.version = UInt32(GIT_COMMIT_CREATE_OPTIONS_VERSION)
        options.allow_empty_commit = allowEmpty ? 1 : 0
        options.author = nil
        options.committer = nil
        options.message_encoding = nil

        return options
    }
}
