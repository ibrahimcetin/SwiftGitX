import libgit2

// ? Can we improve the implementation of the Patch struct?
/// A patch represents changes to a single file.
///
/// It contains a sequence of hunks, each of which represents a contiguous section of the file.
/// Each hunk contains a header and a sequence of lines. Each line represents a change in the file.
public struct Patch: Equatable, Hashable, Sendable {
    /// The delta associated with the patch.
    public let delta: Diff.Delta

    /// The hunks in the patch.
    public let hunks: [Hunk]

    init(pointer: OpaquePointer) {
        // Get the delta associated with the patch
        let deltaPointer = git_patch_get_delta(pointer)
        delta = Diff.Delta(raw: deltaPointer!.pointee)

        // Get hunks
        var hunks = [Hunk]()

        let numberOfHunks = git_patch_num_hunks(pointer)

        for index in 0..<numberOfHunks {
            var hunkPointer: UnsafePointer<git_diff_hunk>?
            var linesCountInHunk = 0

            let hunkStatus = git_patch_get_hunk(&hunkPointer, &linesCountInHunk, pointer, index)

            guard let rawHunk = hunkPointer?.pointee, hunkStatus == GIT_OK.rawValue else {
                continue
            }

            // Get lines
            var lines = [Hunk.Line]()

            for lineIndex in 0..<linesCountInHunk {
                var linePointer: UnsafePointer<git_diff_line>?
                let lineStatus = git_patch_get_line_in_hunk(&linePointer, pointer, index, lineIndex)

                guard let rawLine = linePointer?.pointee, lineStatus == GIT_OK.rawValue else {
                    continue
                }

                let line = Hunk.Line(raw: rawLine)
                lines.append(line)
            }

            let hunk = Hunk(raw: rawHunk, lines: lines)
            hunks.append(hunk)
        }

        self.hunks = hunks
    }

    /// A hunk represents a contiguous section of a file.
    ///
    /// It contains a header and a sequence of lines.
    /// Each line represents a change in the file.
    public struct Hunk: Equatable, Hashable, Sendable {
        /// The header of the hunk.
        public let header: String

        /// The lines in the hunk. Each line represents a change in the file.
        public let lines: [Line]

        /// The starting line number in the old file.
        public let oldStart: Int

        /// The number of lines in the old file.
        public let oldLines: Int

        /// The starting line number in the new file.
        public let newStart: Int

        /// The number of lines in the new file.
        public let newLines: Int

        init(raw: git_diff_hunk, lines: [Line]) {
            var header = raw.header
            self.header = withUnsafePointer(to: &header) {
                $0.withMemoryRebound(to: UInt8.self, capacity: raw.header_len) {
                    String(cString: $0)
                }
            }

            oldStart = Int(raw.old_start)
            oldLines = Int(raw.old_lines)

            newStart = Int(raw.new_start)
            newLines = Int(raw.new_lines)

            self.lines = lines
        }

        /// A line represents a change in a file.
        public struct Line: Equatable, Hashable, Sendable {
            /// The type of the line in the hunk.
            ///
            /// - SeeAlso:  For details ``SwiftGitX/Patch/Hunk/LineType``
            public let type: LineType

            /// The content of the line.
            public let content: String

            /// The offset of the content in the line.
            public let contentOffset: Int

            /// The line number in the file.
            public let lineNumber: Int

            /// The number of new line character (\\n) in the line.
            public let numberOfNewLines: Int

            init(raw: git_diff_line) {
                type = LineType(raw: git_diff_line_t(UInt32(raw.origin)))

                let buffer = UnsafeRawBufferPointer(start: raw.content, count: raw.content_len)
                content = String(decoding: buffer, as: UTF8.self)

                contentOffset = Int(raw.content_offset)

                // Old file line number and new file line number are two distinct variables in libgit
                // but generally one of it is -1. We can use the non -1 value as the line number.
                // ? Is this a good approach? Should we separate the line number into two variables?
                lineNumber = raw.old_lineno == -1 ? Int(raw.new_lineno) : Int(raw.old_lineno)

                numberOfNewLines = Int(raw.num_lines)
            }
        }

        /// The type of the line in the hunk.
        ///
        /// The type of the line can be a context line, an addition line, or a deletion line.
        ///
        /// If the line has no newline character at the end,
        /// it can be a context EOF, an addition EOF, or a deletion EOF.
        public enum LineType: String, Sendable {
            case context = " "
            case addition = "+"
            case deletion = "-"

            case contextEOF = "="
            case additionEOF = ">"
            case deletionEOF = "<"

            init(raw: git_diff_line_t) {
                self =
                    switch raw {
                    case GIT_DIFF_LINE_CONTEXT:
                        .context
                    case GIT_DIFF_LINE_ADDITION:
                        .addition
                    case GIT_DIFF_LINE_DELETION:
                        .deletion
                    case GIT_DIFF_LINE_CONTEXT_EOFNL:
                        .contextEOF
                    case GIT_DIFF_LINE_ADD_EOFNL:
                        .additionEOF
                    case GIT_DIFF_LINE_DEL_EOFNL:
                        .deletionEOF
                    default:
                        .context
                    }
            }
        }
    }
}
