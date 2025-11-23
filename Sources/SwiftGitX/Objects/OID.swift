import libgit2

public enum OIDError: Error {
    case invalid(String)
}

/// An Object ID representation in the repository.
///
/// The OID is a unique 40-byte length hex string that an object in the repository is identified with.
/// Commits, trees, blobs, and tags all have an OID.
///
/// You can also get an abbreviated version of the OID which is an 8-byte length hex string.
public struct OID: LibGit2RawRepresentable {
    /// The zero (null) OID.
    public static let zero: OID = .init(raw: git_oid(id: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)))

    /// The libgit2 git_oid struct that this OID wraps.
    let raw: git_oid

    /// The 40-byte length hex string.
    ///
    /// This is the string representation of the OID.
    public var hex: String {
        hex(length: 40)
    }

    /// The 8-byte length hex string.
    ///
    /// This is the abbreviated string representation of the OID.
    public var abbreviated: String {
        hex(length: 8)
    }

    /// Create an OID from a git_oid.
    ///
    /// - Parameter oid: The git_oid.
    init(raw: git_oid) {
        self.raw = raw
    }

    /// Create an OID from a hex string.
    ///
    /// - Parameter hex: The 40-byte length hex string.
    public init(hex: String) throws {
        var raw = git_oid()
        let status = git_oid_fromstr(&raw, hex)

        guard status == GIT_OK.rawValue else {
            let errorMessage = String(cString: git_error_last().pointee.message)
            throw OIDError.invalid(errorMessage)
        }

        self.raw = raw
    }

    private func hex(length: Int) -> String {
        var oid = raw

        let bufferLength = length + 1  // +1 for \0 terminator
        var buffer = [Int8](repeating: 0, count: bufferLength)

        git_oid_tostr(&buffer, bufferLength, &oid)

        return String(cString: buffer)
    }
}

extension OID {
    public static func == (lhs: OID, rhs: OID) -> Bool {
        var left = lhs.raw
        var right = rhs.raw

        return git_oid_cmp(&left, &right) == 0
    }

    public func hash(into hasher: inout Hasher) {
        withUnsafeBytes(of: raw.id) { hasher.combine(bytes: $0) }
    }
}
