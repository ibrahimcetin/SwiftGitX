import Foundation
import libgit2

public enum SignatureError: Error {
    case invalid(String)
    case notFound(String)
}

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
    public static func `default`(in repositoryPointer: OpaquePointer) throws -> Signature {
        var signature: UnsafeMutablePointer<git_signature>?
        defer { git_signature_free(signature) }

        let status = git_signature_default(&signature, repositoryPointer)

        guard let signature = signature?.pointee else {
            let errorMessage = String(cString: git_error_last().pointee.message)

            switch status {
            case GIT_ENOTFOUND.rawValue:
                throw SignatureError.notFound(errorMessage)
            default:
                throw SignatureError.invalid(errorMessage)
            }
        }

        return Signature(raw: signature)
    }
}
