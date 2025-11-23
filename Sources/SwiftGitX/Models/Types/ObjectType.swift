import libgit2

public enum ObjectType: LibGit2RawRepresentable {
    case any
    case invalid
    case commit
    case tree
    case blob
    case tag

    init(raw: git_object_t) {
        self = Self.objectTypeMapping.first(where: { $0.value == raw })?.key ?? .invalid
    }

    var raw: git_object_t {
        ObjectType.objectTypeMapping[self] ?? GIT_OBJECT_INVALID
    }
}

extension ObjectType {
    fileprivate static let objectTypeMapping: [ObjectType: git_object_t] = [
        .any: GIT_OBJECT_ANY,
        .invalid: GIT_OBJECT_INVALID,
        .commit: GIT_OBJECT_COMMIT,
        .tree: GIT_OBJECT_TREE,
        .blob: GIT_OBJECT_BLOB,
        .tag: GIT_OBJECT_TAG
    ]
}
