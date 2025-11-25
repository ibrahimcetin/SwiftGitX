//
//  SwiftGitX.swift
//  SwiftGitX
//
//  Created by İbrahim Çetin on 23.11.2025.
//

import libgit2

/// The main entry point for the SwiftGitX library.
public enum SwiftGitX {
    /// Initialize the SwiftGitX
    ///
    /// - Returns: the number of initializations of the library.
    ///
    /// This function must be called before any other libgit2 function in order to set up global state and threading.
    ///
    /// This function may be called multiple times. It will return the number of times the initialization has been
    /// called (including this one) that have not subsequently been shutdown.
    @discardableResult
    public static func initialize() throws(SwiftGitXError) -> Int {
        // Initialize the libgit2 library
        let status = git_libgit2_init()

        try SwiftGitXError.check(status, operation: .initialize)

        return Int(status)
    }

    /// Shutdown the SwiftGitX
    ///
    /// - Returns: the number of shutdowns of the library.
    ///
    /// Clean up the global state and threading context after calling it as many times as ``initialize()`` was called.
    /// It will return the number of remaining initializations that have not been shutdown (after this one).
    @discardableResult
    public static func shutdown() throws(SwiftGitXError) -> Int {
        // Shutdown the libgit2 library
        let status = git_libgit2_shutdown()

        try SwiftGitXError.check(status, operation: .shutdown)

        return Int(status)
    }

    /// The version of the libgit2 library.
    public static var libgit2Version: String {
        var major: Int32 = 0
        var minor: Int32 = 0
        var patch: Int32 = 0

        git_libgit2_version(&major, &minor, &patch)

        return "\(major).\(minor).\(patch)"
    }
}

extension SwiftGitXError.Operation {
    public static let initialize = Self(rawValue: "initialize")
    public static let shutdown = Self(rawValue: "shutdown")
}
