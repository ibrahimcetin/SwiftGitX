import libgit2

/// Options for reset operation.
public enum ResetOption: LibGit2RawRepresentable {
    /// Does not touch the index file or the working tree at all
    /// (but resets the head to `commit`, just like all modes do).
    case soft

    /// Resets the index but not the working tree.
    /// (i.e., the changed files are preserved but not marked for commit)
    case mixed

    /// Resets the index and working tree. Any changes to tracked files in the working tree
    /// since `commit` are discarded. Any untracked files or directories in the way of
    /// writing any tracked files are simply deleted.
    case hard

    init(raw: git_reset_t) {
        self =
            switch raw {
            case GIT_RESET_SOFT:
                .soft
            case GIT_RESET_MIXED:
                .mixed
            case GIT_RESET_HARD:
                .hard
            default:
                .soft
            }
    }

    var raw: git_reset_t {
        switch self {
        case .soft:
            GIT_RESET_SOFT
        case .mixed:
            GIT_RESET_MIXED
        case .hard:
            GIT_RESET_HARD
        }
    }
}
