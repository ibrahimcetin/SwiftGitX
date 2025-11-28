import libgit2

/// Represents the differences between two trees.
public struct Diff: Equatable, Hashable {
    /// The changed files in the diff.
    ///
    /// Each delta represents a file change. The delta contains the status of the change,
    /// the old and new file, and the flags.
    ///
    /// If you want to get each file change in detail, you can use the ``patches`` property.
    /// It provides changes line by line. Each patch represents a file change.
    public let changes: [Delta]

    /// The file patches in the diff. Each patch represents a file change.
    ///
    /// A patch is a collection of hunks that represent the changes in a file.
    /// Each hunk is a collection of lines that represent the changes in a specific part of the file.
    public let patches: [Patch]

    init(pointer: OpaquePointer) {
        var deltas = [Delta]()
        var patches = [Patch]()

        // Get the number of deltas in the diff
        let numberOfDeltas = git_diff_num_deltas(pointer)

        // Iterate over the deltas and append them to the array
        for index in 0..<numberOfDeltas {
            let deltaPointer = git_diff_get_delta(pointer, index)

            // If delta pointer is not nil, create a new delta
            if let rawDelta = deltaPointer?.pointee {
                // Create a new delta from the raw delta
                let delta = Delta(raw: rawDelta)
                // Append the delta to the array
                deltas.append(delta)
            }

            // Create patches
            var patchPointer: OpaquePointer?
            defer { git_patch_free(patchPointer) }

            let patchStatus = git_patch_from_diff(&patchPointer, pointer, index)

            // If the patch pointer is not nil, create a new patch
            if let patchPointer, patchStatus == GIT_OK.rawValue {
                let patch = Patch(pointer: patchPointer)
                patches.append(patch)
            }
        }

        changes = deltas
        self.patches = patches
    }
}

// MARK: - Structs

extension Diff {
    public struct Delta: LibGit2RawRepresentable {
        /// The type of the delta.
        public let type: DeltaType

        /// The `oldFile` represents the "from" side of the diff.
        public let oldFile: File

        /// The `newFile` represents the "to" side of the diff.
        public let newFile: File

        /// The flags of the delta.
        public let flags: [Flag]

        /// The similarity between the files for "renamed" or "copied" status (0-100).
        public let similarity: Int

        /// The number of files in the delta.
        public let numberOfFiles: Int

        // Represents git_diff_file in libgit2.
        nonisolated(unsafe) let raw: git_diff_delta

        init(raw: git_diff_delta) {
            type = DeltaType(rawValue: Int(raw.status.rawValue))!

            oldFile = File(raw: raw.old_file)
            newFile = File(raw: raw.new_file)

            flags = Flag.from(raw.flags)
            similarity = Int(raw.similarity)
            numberOfFiles = Int(raw.nfiles)

            self.raw = raw
        }

        public static func == (lhs: Diff.Delta, rhs: Diff.Delta) -> Bool {
            lhs.type == rhs.type && lhs.oldFile == rhs.oldFile && lhs.newFile == rhs.newFile && lhs.flags == rhs.flags
                && lhs.similarity == rhs.similarity && lhs.numberOfFiles == rhs.numberOfFiles
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(type)
            hasher.combine(oldFile)
            hasher.combine(newFile)
            hasher.combine(flags)
            hasher.combine(similarity)
            hasher.combine(numberOfFiles)
        }
    }

    public struct File: LibGit2RawRepresentable {
        /// The ID of the object.
        public let id: OID

        /// The path of the file relative to the repository working directory.
        public let path: String

        /// The size of the entry in bytes.
        public let size: Int

        /// The flags of the file.
        public let flags: [Flag]

        /// The mode of the file.
        public let mode: FileMode

        nonisolated(unsafe) let raw: git_diff_file

        init(raw: git_diff_file) {
            id = OID(raw: raw.id)
            path = String(cString: raw.path)
            size = Int(raw.size)
            flags = Flag.from(raw.flags)
            mode = FileMode(raw: git_filemode_t(rawValue: UInt32(raw.mode)))

            self.raw = raw
        }

        public static func == (lhs: Diff.File, rhs: Diff.File) -> Bool {
            lhs.id == rhs.id && lhs.path == rhs.path && lhs.size == rhs.size && lhs.flags == rhs.flags
                && lhs.mode == rhs.mode
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(path)
            hasher.combine(size)
            hasher.combine(flags)
            hasher.combine(mode)
        }
    }
}

// MARK: - Enums

extension Diff {
    // Represents git_diff_flag_t enum in libgit2
    public enum Flag: Sendable {
        /// The file is binary.
        case binary

        /// The file is not binary.
        case notBinary

        /// The file id is valid.
        case validID

        /// The file exists at this side of the delta.
        case exists

        /// The file size is valid.
        case validSize

        static func from(_ flags: UInt32) -> [Flag] {
            var result = [Flag]()

            if flags & GIT_DIFF_FLAG_BINARY.rawValue != 0 {
                result.append(.binary)
            }

            if flags & GIT_DIFF_FLAG_NOT_BINARY.rawValue != 0 {
                result.append(.notBinary)
            }

            if flags & GIT_DIFF_FLAG_VALID_ID.rawValue != 0 {
                result.append(.validID)
            }

            if flags & GIT_DIFF_FLAG_EXISTS.rawValue != 0 {
                result.append(.exists)
            }

            if flags & GIT_DIFF_FLAG_VALID_SIZE.rawValue != 0 {
                result.append(.validSize)
            }

            return result
        }
    }
}

extension Diff {
    // Represents git_delta_t enum in libgit2
    /// Represents what type of change is described by ``Delta``.
    public enum DeltaType: Int, Sendable {
        /// No changes
        case unmodified = 0

        /// Entry does not exist in old version
        case added

        /// Entry does not exist in new version
        case deleted

        /// Entry content changed between old and new
        case modified

        /// Entry was renamed between old and new
        case renamed

        /// Entry was copied from another old entry
        case copied

        /// Entry is ignored item in working tree
        case ignored

        /// Entry is untracked item in working tree
        case untracked

        /// Type of entry changed between old and new
        case typeChange

        /// Entry is unreadable
        case unreadable

        /// Entry in the index is conflicted
        case conflicted
    }
}
