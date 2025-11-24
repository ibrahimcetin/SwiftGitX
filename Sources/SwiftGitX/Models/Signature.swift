import Foundation
import libgit2

// ? Can we use LibGit2RawRepresentable here?
/// A signature representation in the repository.
public struct Signature: Equatable, Hashable {
    /// The full name of the author.
    public let name: String

    /// The email of the author.
    public let email: String

    /// The date of the action happened.
    public let date: Date

    /// The timezone of the author.
    public let timezone: TimeZone

    init(raw: git_signature) {
        name = String(cString: raw.name)
        email = String(cString: raw.email)
        date = Date(timeIntervalSince1970: TimeInterval(raw.when.time))
        timezone = TimeZone(secondsFromGMT: Int(raw.when.offset) * 60) ?? TimeZone.current
    }
}

extension Signature {
    public static func `default`(in repositoryPointer: OpaquePointer) throws(SwiftGitXError) -> Signature {
        let signaturePointer = try git {
            var signaturePointer: UnsafeMutablePointer<git_signature>?
            let status = git_signature_default(&signaturePointer, repositoryPointer)
            return (signaturePointer, status)
        }
        defer { git_signature_free(signaturePointer) }

        return Signature(raw: signaturePointer.pointee)
    }
}
