import Foundation
import SwiftGitX
import Testing

/// Base class for SwiftGitX tests to initialize and shutdown the library
///
/// - Important: Inherit from this class to create a test suite.
class SwiftGitXTest {
    /// Creates a new mock repository with auto-generated unique name based on the calling test.
    ///
    /// This method automatically generates a unique repository name using the file and function
    /// where it's called, making it perfect for parallel test execution.
    ///
    /// - Parameters:
    ///   - fileID: Automatically captured file identifier.
    ///   - name: The name of the mock repository to create.
    ///   - suffix: Suffix to add to the directory name.
    ///   - isBare: Whether to create a bare repository.
    ///
    /// - Returns: The created repository.
    func mockRepository(
        fileID: String = #fileID,
        name: String = #function,
        suffix: String = "",
        isBare: Bool = false
    ) -> Repository {
        // Create a new mock directory
        let directory = mockDirectory(fileID: fileID, name: name, suffix: suffix)

        // Create the repository
        return try! Repository.create(at: directory, isBare: isBare)
    }

    /// Creates a new mock directory with auto-generated unique name based on the calling test.
    ///
    /// This method automatically generates a unique directory name using the file and function
    /// where it's called, making it perfect for parallel test execution.
    ///
    /// - Parameters:
    ///   - fileID: Automatically captured file identifier.
    ///   - name: The name of the mock directory to create.
    ///   - suffix: Suffix to add to the directory name.
    ///   - create: Whether to create the directory or not (default: false).
    ///
    /// - Returns: The created directory.
    func mockDirectory(
        fileID: String = #fileID,
        name: String = #function,
        suffix: String = "",
        create: Bool = false
    ) -> URL {
        // Get the suite name
        let suiteName = String(describing: Self.self)

        // Extract file name from fileID
        // fileID format: "SwiftGitXTests/Collections/BranchCollectionTests.swift"
        let fileName = fileID.components(separatedBy: "/").last!.replacing(".swift", with: "")

        // Extract name
        // name format: "testBranchLookup()" or "branchLookup()"
        let directoryName = name.replacing("()", with: "").replacing("test", with: "") + suffix

        // Create the directory
        let directory = URL.temporaryDirectory
            .appending(components: "SwiftGitXTests", fileName, suiteName, directoryName)

        // Remove the directory if it already exists to create an empty repository
        if FileManager.default.fileExists(atPath: directory.path) {
            try! FileManager.default.removeItem(at: directory)
        }

        // Create the directory
        if create {
            try! FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
        }

        return directory
    }

    #if os(iOS) || os(tvOS) || os(watchOS)
        private actor TestConfigurator {
            private var isConfigured = false

            func configureIfNeeded() throws {
                guard !isConfigured else { return }
                try SwiftGitXRuntime.initialize()

                try Repository.config.set("user.name", to: "SwiftGitX Tests")
                try Repository.config.set("user.email", to: "swiftgitx@tests.com")
                try Repository.config.set("init.defaultBranch", to: "main")

                try SwiftGitXRuntime.shutdown()
                isConfigured = true
            }
        }

        private static let configurator = TestConfigurator()

        init() async throws {
            try await Self.configurator.configureIfNeeded()
        }
    #else
        init() throws {}
    #endif
}

// Test the SwiftGitXRuntime enum to initialize and shutdown the library
@Suite("SwiftGitX Runtime Tests", .tags(.runtime), .serialized)
struct SwiftGitXRuntimeTests {
    @Test("Test SwiftGitXRuntime Initialize")
    func initialize() async throws {
        // Initialize the SwiftGitXRuntime
        let count = try SwiftGitXRuntime.initialize()

        // Check if the initialization count is valid
        #expect(count > 0)
    }

    @Test("Test SwiftGitXRuntime Shutdown")
    func shutdown() async throws {
        // Shutdown the SwiftGitXRuntime
        let count = try SwiftGitXRuntime.shutdown()

        // Check if the shutdown count is valid
        #expect(count >= 0)
    }

    @Test(
        "Test SwiftGitXRuntime Shutdown Without Calling Initialize",
        .disabled("This test is disabled because it should be skipped while running all tests. Enable if you want.")
    )
    func shutdownWithoutInitialize() async throws {
        // Shutdown the SwiftGitXRuntime
        let error = #expect(throws: SwiftGitXError.self) {
            try SwiftGitXRuntime.shutdown()
        }

        // Check if the error is a SwiftGitXError
        #expect(error?.code == .error)

        // Note: This is a quirk of libgit2's design. When shutdown() is called before initialize(),
        // it decrements the initialization count below 0 and returns a negative status code (error),
        // but git_error_last() returns no actual error object because libgit2 doesn't set one for
        // this particular case. Hence we get error code .error, but category .none and message "no error".
        //
        // We still throw an error because shutdown should not be called without initialize, even though
        // the error message is uninformative. This error can be ignored if needed.
        #expect(error?.category == SwiftGitXError.Category.none)
        #expect(error?.message == "no error")
    }

    @Test("Test libgit2 version")
    func libgit2Version() throws {
        // Get the libgit2 version
        let version = SwiftGitXRuntime.libgit2Version

        // Check if the version is valid
        #expect(version == "1.9.0")
    }
}
