import libgit2

public enum FileMode: UInt32, LibGit2RawRepresentable {
    case unreadable = 0_000_000
    case tree = 0_040_000
    case blob = 0_100_644
    case blobExecutable = 0_100_755
    case symlink = 0_120_000
    case commit = 0_160_000

    init(raw: git_filemode_t) {
        self =
            switch raw {
            case GIT_FILEMODE_UNREADABLE:
                .unreadable
            case GIT_FILEMODE_TREE:
                .tree
            case GIT_FILEMODE_BLOB:
                .blob
            case GIT_FILEMODE_BLOB_EXECUTABLE:
                .blobExecutable
            case GIT_FILEMODE_LINK:
                .symlink
            case GIT_FILEMODE_COMMIT:
                .commit
            default:
                .unreadable
            }
    }

    var raw: git_filemode_t {
        git_filemode_t(rawValue)
    }
}
