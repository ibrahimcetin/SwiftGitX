import Foundation
import libgit2

// ? Can we use LibGit2RawRepresentable here?
/// A signature representation in the repository.
public struct Signature: Equatable, Hashable, Sendable {
    /// The full name of the author.
    public let name: String

    /// The email of the author.
    public let email: String

    /// The date of the action happened.
    public let date: Date

    /// The timezone of the author.
    public let timezone: TimeZone

    /// Initializes a new signature.
    ///
    /// - Parameters:
    ///   - name: The full name of the author.
    ///   - email: The email of the author.
    ///   - date: The date of the action. Defaults to the current date.
    ///   - timezone: The timezone of the author. Defaults to the system timezone.
    ///
    /// If `date` and `timezone` are not provided, the current date and system timezone are used.
    public init(name: String, email: String, date: Date = Date(), timezone: TimeZone = .current) {
        self.name = name
        self.email = email
        self.date = date
        self.timezone = timezone
    }
}

extension Signature {
    init(pointer: UnsafePointer<git_signature>) {
        let raw = pointer.pointee

        name = String(cString: raw.name)
        email = String(cString: raw.email)
        date = Date(timeIntervalSince1970: TimeInterval(raw.when.time))
        timezone = TimeZone(secondsFromGMT: Int(raw.when.offset) * 60) ?? TimeZone.current
    }
}

extension Signature {
    /// Returns the default signature for the repository.
    ///
    /// - Parameter repository: The repository to get the default signature for.
    ///
    /// - Returns: The default signature for the repository.
    public static func `default`(in repository: Repository) throws(SwiftGitXError) -> Signature {
        try `default`(in: repository.pointer)
    }

    internal static func `default`(in repositoryPointer: OpaquePointer) throws(SwiftGitXError) -> Signature {
        let signaturePointer = try git(operation: .signature) {
            var signaturePointer: UnsafeMutablePointer<git_signature>?
            let status = git_signature_default(&signaturePointer, repositoryPointer)
            return (signaturePointer, status)
        }
        defer { git_signature_free(signaturePointer) }

        return Signature(pointer: signaturePointer)
    }
}

extension SwiftGitXError.Operation {
    public static let signature = Self(rawValue: "signature")
}
