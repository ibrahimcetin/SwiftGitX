//
//  OID.swift
//  SwiftGitX
//
//  Created by İbrahim Çetin on 24.11.2025.
//

import libgit2

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
    public init(hex: String) throws(SwiftGitXError) {
        var raw = git_oid()

        try git {
            git_oid_fromstr(&raw, hex)
        }

        self.raw = raw
    }

    private func hex(length: Int) -> String {
        var oid = raw

        let bufferLength = length + 1  // +1 for \0 terminator
        var buffer = [Int8](repeating: 0, count: bufferLength)

        git_oid_tostr(&buffer, bufferLength, &oid)

        let bytes = buffer.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }
        return String(decoding: bytes, as: UTF8.self)
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
