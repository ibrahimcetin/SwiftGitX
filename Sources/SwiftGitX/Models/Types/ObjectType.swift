import libgit2

public enum ObjectType: LibGit2RawRepresentable {
    case any
    case invalid
    case commit
    case tree
    case blob
    case tag
    case offsetDelta
    case referenceDelta

    init(raw: git_object_t) {
        self = Self.objectTypeMapping.first(where: { $0.value == raw })?.key ?? .invalid
    }

    var raw: git_object_t {
        ObjectType.objectTypeMapping[self] ?? GIT_OBJECT_INVALID
    }
}

extension ObjectType: Sendable {}

private extension ObjectType {
    static let objectTypeMapping: [ObjectType: git_object_t] = [
        .any: GIT_OBJECT_ANY,
        .invalid: GIT_OBJECT_INVALID,
        .commit: GIT_OBJECT_COMMIT,
        .tree: GIT_OBJECT_TREE,
        .blob: GIT_OBJECT_BLOB,
        .tag: GIT_OBJECT_TAG,
        .offsetDelta: GIT_OBJECT_OFS_DELTA,
        .referenceDelta: GIT_OBJECT_REF_DELTA
    ]
}
