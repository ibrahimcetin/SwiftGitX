//
//  SwiftGitXError.swift
//  SwiftGitX
//
//  Created by İbrahim Çetin on 23.11.2025.
//

import libgit2

/// Executes a Git operation and automatically checks for errors.
///
/// This function wraps libgit2 calls and automatically checks the returned
/// status code, throwing `SwiftGitXError` if the operation fails.
///
/// - Parameters:
///   - operation: Optional operation context for error reporting.
///   - call: The libgit2 function call that returns a status code.
///
/// - Throws: `SwiftGitXError` if the operation fails.
///
/// ## Example
///
/// ```swift
/// try git {
///     git_commit_create_from_stage(&oid, pointer, message, &options)
/// }
///
/// // With operation context
/// try git(operation: .push) {
///     git_push(remote, refspecs, options)
/// }
/// ```
func git(
    operation: SwiftGitXError.Operation? = nil,
    _ call: () -> Int32
) throws(SwiftGitXError) {
    let status = call()
    try SwiftGitXError.check(status, operation: operation)
}

/// Executes a Git operation that returns a pointer and automatically checks for errors.
///
/// - Parameters:
///   - operation: Optional operation context for error reporting.
///   - call: A closure that returns a tuple of (optional pointer, status code).
///
/// - Returns: The validated non-nil pointer.
/// - Throws: `SwiftGitXError` if the operation fails or pointer is nil.
///
/// ## Example
///
/// ```swift
/// let pointer = try git(operation: .clone) {
///     var pointer: OpaquePointer?
///     let status = git_clone(&pointer, remoteURL.absoluteString, localURL.path, &options)
///     return (pointer, status)
/// }
/// ```
///
/// - Important: The returned pointer must be released with appropriate `git_<type>_free` function when no longer needed.
func git<T>(
    operation: SwiftGitXError.Operation? = nil,
    _ call: () -> (T?, Int32)
) throws(SwiftGitXError) -> T {
    let (pointer, status) = call()
    return try SwiftGitXError.check(status, pointer: pointer, operation: operation)
}

/// An error that occurs during Git operations.
///
/// `SwiftGitXError` provides detailed information about errors encountered
/// while performing Git operations. Each error includes:
/// - A ``code`` indicating what went wrong
/// - A ``category`` identifying where the error originated
/// - A human-readable ``message`` describing the error
public struct SwiftGitXError: Error, Sendable {
    /// The error code indicating what went wrong.
    public let code: Code

    /// The operation that caused the error.
    public let operation: Operation?

    /// The error category identifying where the error originated.
    public let category: Category

    /// A human-readable description of the error.
    public let message: String

    init(code: Code, operation: Operation? = nil, category: Category, message: String) {
        self.code = code
        self.operation = operation
        self.category = category
        self.message = message
    }
}

extension SwiftGitXError {
    /// Initializes a SwiftGitXError with the given status code and operation.
    ///
    /// - Parameters:
    ///   - status: The status code returned by a libgit2 operation.
    ///   - operation: The operation that caused the error.
    ///
    /// - Returns: A SwiftGitXError with the given status code and operation.
    ///
    /// - Important: This initializer reads the last error from libgit2 and sets the category and message.
    private init(status: Int32, operation: Operation? = nil) {
        self.code = Code(rawValue: Int(status)) ?? .error

        self.operation = operation

        // If the status is less than 0, we have an error.
        // Get the error message from the last error.
        if status < 0, let error = git_error_last() {
            self.category = Category(rawValue: Int(error.pointee.klass)) ?? .none
            self.message = String(cString: error.pointee.message)
        } else {
            self.category = .none
            self.message = "no error"
        }
    }
}

// MARK: - Error Checking Helper

extension SwiftGitXError {
    /// Throws SwiftGitXError if status indicates an error.
    ///
    /// - Parameter status: The status code returned by a libgit2 operation.
    /// - Throws: `SwiftGitXError` if the status code indicates an error (negative value).
    ///
    /// ## Example
    ///
    /// ```swift
    /// let status = git_commit_create_from_stage(&oid, pointer, message, &options)
    /// try SwiftGitXError.check(status)
    /// ```
    @inline(__always)
    static func check(_ status: Int32, operation: Operation? = nil) throws(SwiftGitXError) {
        // If the status is less than 0, we have an error.
        guard status >= 0 else {
            throw SwiftGitXError(status: status, operation: operation)
        }
    }

    /// Throws SwiftGitXError if status indicates an error and pointer is nil.
    ///
    /// - Parameters:
    ///   - status: The status code returned by a libgit2 operation.
    ///   - pointer: The pointer returned from a libgit2 operation.
    /// - Returns: The non-optional pointer of the same type.
    ///
    /// This generic method validates that the pointer is non-nil after a successful operation.
    /// A nil pointer after successful status is unexpected and indicates an internal error.
    @inline(__always)
    static func check<T>(_ status: Int32, pointer: T?, operation: Operation? = nil) throws(SwiftGitXError) -> T {
        // Check if the status is successful
        try check(status, operation: operation)

        // Check if the pointer is non-nil
        guard let pointer else {
            // This should never happen, but if it does, we throw an internal error.
            throw SwiftGitXError(
                code: .error, operation: operation, category: .internal,
                message: "Unexpected nil pointer after successful operation"
            )
        }

        return pointer
    }
}

extension SwiftGitXError {
    /// Error codes returned by Git operations.
    ///
    /// Each case represents a specific error condition that can occur during
    /// Git operations. A return value of ``ok`` (0) indicates successful completion,
    /// while negative values indicate various error conditions.
    ///
    /// This enum directly reflects libgit2's `git_error_code` enumeration.
    /// The raw values correspond to the integer error codes returned directly
    /// by libgit2's operation functions.
    ///
    /// - Note: This is distinct from ``Category``, which provides additional context about
    /// where the error originated (e.g., network, filesystem, repository).
    public enum Code: Int, Sendable {
        /// No error occurred; the call was successful.
        case ok = 0

        /// An error occurred; call git_error_last for more information.
        case error = -1

        /// Requested object could not be found.
        case notFound = -3

        /// Object exists preventing operation.
        case exists = -4

        /// More than one object matches.
        case ambiguous = -5

        /// Output buffer too short to hold data.
        case bufs = -6

        /// GIT_EUSER is a special error that is never generated by libgit2 code.
        /// You can return it from a callback (e.g to stop an iteration) to know that
        /// it was generated by the callback and not by libgit2.
        case user = -7

        /// Operation not allowed on bare repository.
        case bareRepo = -8

        /// HEAD refers to branch with no commits.
        case unbornBranch = -9

        /// Merge in progress prevented operation.
        case unmerged = -10

        /// Reference was not fast-forwardable.
        case nonFastForward = -11

        /// Name/ref spec was not in a valid format.
        case invalidSpec = -12

        /// Checkout conflicts prevented operation.
        case conflict = -13

        /// Lock file prevented operation.
        case locked = -14

        /// Reference value does not match expected.
        case modified = -15

        /// Authentication error.
        case auth = -16

        /// Server certificate is invalid.
        case certificate = -17

        /// Patch/merge has already been applied.
        case applied = -18

        /// The requested peel operation is not possible.
        case peel = -19

        /// Unexpected EOF.
        case eof = -20

        /// Invalid operation or input.
        case invalid = -21

        /// Uncommitted changes in index prevented operation.
        case uncommitted = -22

        /// The operation is not valid for a directory.
        case directory = -23

        /// A merge conflict exists and cannot continue.
        case mergeConflict = -24

        /// A user-configured callback refused to act.
        case passthrough = -30

        /// Signals end of iteration with iterator.
        case iterOver = -31

        /// Internal only.
        case retry = -32

        /// Hashsum mismatch in object.
        case mismatch = -33

        /// Unsaved changes in the index would be overwritten.
        case indexDirty = -34

        /// Patch application failed.
        case applyFail = -35

        /// The object is not owned by the current user.
        case owner = -36

        /// The operation timed out.
        case timeout = -37

        /// There were no changes.
        case unchanged = -38

        /// An option is not supported.
        case notSupported = -39

        /// The subject is read-only.
        case readOnly = -40
    }

    /// Error categories that identify where an error originated.
    ///
    /// Each category identifies the subsystem or component where the error occurred.
    /// Unlike ``Code``, which indicates what went wrong, categories help classify
    /// errors by their source (e.g., network, filesystem, repository, SSL).
    ///
    /// This enum directly reflects libgit2's `git_error_t` enumeration.
    /// Error categories are obtained by calling `git_error_last` to get additional
    /// context about the error beyond the error code returned by the operation.
    public enum Category: Int, Sendable {
        /// No error.
        case none = 0

        /// Out of memory.
        case noMemory = 1

        /// Operating system error.
        case os = 2

        /// Invalid input.
        case invalid = 3

        /// Reference error.
        case reference = 4

        /// Zlib compression/decompression error.
        case zlib = 5

        /// Repository error.
        case repository = 6

        /// Configuration error.
        case config = 7

        /// Regular expression error.
        case regex = 8

        /// Object database error.
        case odb = 9

        /// Index error.
        case index = 10

        /// Object error.
        case object = 11

        /// Network error.
        case net = 12

        /// Tag error.
        case tag = 13

        /// Tree error.
        case tree = 14

        /// Indexer error.
        case indexer = 15

        /// SSL error.
        case ssl = 16

        /// Submodule error.
        case submodule = 17

        /// Threading error.
        case thread = 18

        /// Stash error.
        case stash = 19

        /// Checkout error.
        case checkout = 20

        /// FETCH_HEAD error.
        case fetchHead = 21

        /// Merge error.
        case merge = 22

        /// SSH error.
        case ssh = 23

        /// Filter error.
        case filter = 24

        /// Revert error.
        case revert = 25

        /// Callback error.
        case callback = 26

        /// Cherry-pick error.
        case cherryPick = 27

        /// Describe error.
        case describe = 28

        /// Rebase error.
        case rebase = 29

        /// Filesystem error.
        case filesystem = 30

        /// Patch error.
        case patch = 31

        /// Worktree error.
        case worktree = 32

        /// SHA-1 computation error.
        case sha = 33

        /// HTTP error.
        case http = 34

        /// Internal libgit2 error.
        case `internal` = 35

        /// Grafts error.
        case grafts = 36
    }

    public struct Operation: RawRepresentable, Sendable {
        public static let config = Operation(rawValue: "config")
        public static let clone = Operation(rawValue: "clone")
        public static let checkout = Operation(rawValue: "checkout")
        public static let commit = Operation(rawValue: "commit")
        public static let diff = Operation(rawValue: "diff")
        public static let fetch = Operation(rawValue: "fetch")
        public static let head = Operation(rawValue: "head")
        public static let index = Operation(rawValue: "index")
        public static let merge = Operation(rawValue: "merge")
        public static let patch = Operation(rawValue: "patch")
        public static let pull = Operation(rawValue: "pull")
        public static let push = Operation(rawValue: "push")
        public static let reset = Operation(rawValue: "reset")
        public static let restore = Operation(rawValue: "restore")
        public static let revert = Operation(rawValue: "revert")
        public static let status = Operation(rawValue: "status")
        public static let `switch` = Operation(rawValue: "switch")

        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }
}

// MARK: - Code Convenience Properties

extension SwiftGitXError.Code {
    /// Returns true if the error indicates object/reference not found.
    public var isNotFound: Bool { self == .notFound }

    /// Returns true if the error indicates a conflict condition.
    public var isConflict: Bool { self == .conflict || self == .mergeConflict }

    /// Returns true if the error is authentication-related.
    public var isAuth: Bool { self == .auth || self == .certificate }

    /// Returns true if a resource is locked.
    public var isLocked: Bool { self == .locked }

    /// Returns true if the operation requires force flag.
    public var requiresForce: Bool { self == .nonFastForward }

    /// Returns true if there are uncommitted changes.
    public var hasUncommittedChanges: Bool { self == .uncommitted || self == .modified }
}

extension SwiftGitXError: CustomDebugStringConvertible {
    public var debugDescription: String {
        """

        ┌─ SwiftGitXError ────────────────────────────
        │ Operation: \(operation?.rawValue ?? "(none)")
        │ Code:      \(code)
        │ Category:  \(category)
        │ Message:   \(message)
        └─────────────────────────────────────────────
        """
    }
}
