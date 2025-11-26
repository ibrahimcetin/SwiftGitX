import SwiftGitX
import Testing
import XCTest

class SwiftGitXTestCase: XCTestCase {
    static var directory: String {
        String(describing: Self.self)
    }

    override class func setUp() {
        super.setUp()

        // Initialize the SwiftGitX library
        XCTAssertNoThrow(try SwiftGitXRuntime.initialize())
    }

    override class func tearDown() {
        // Shutdown the SwiftGitX library
        XCTAssertNoThrow(try SwiftGitXRuntime.shutdown())

        // Remove the temporary directory for the tests
        try? FileManager.default.removeItem(at: Repository.testsDirectory.appending(component: directory))

        super.tearDown()
    }
}

/// Base class for SwiftGitX tests to initialize and shutdown the library
///
/// - Important: Inherit from this class to create a test suite.
class SwiftGitXTest {
    static var directory: String {
        String(describing: Self.self)
    }

    /// Creates a new mock repository with auto-generated unique name based on the calling test.
    ///
    /// This method automatically generates a unique repository name using the file and function
    /// where it's called, making it perfect for parallel test execution.
    ///
    /// - Parameters:
    ///   - fileID: Automatically captured file identifier.
    ///   - function: Automatically captured function name.
    ///   - isBare: Whether to create a bare repository.
    ///
    /// - Returns: The created repository.
    func mockRepository(
        fileID: String = #fileID,
        function: String = #function,
        isBare: Bool = false
    ) -> Repository {
        // Create a new mock directory
        let directory = mockDirectory(fileID: fileID, function: function)

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
    ///   - function: Automatically captured function name.
    ///   - create: Whether to create the directory or not (default: false).
    ///
    /// - Returns: The created directory.
    func mockDirectory(fileID: String = #fileID, function: String = #function, create: Bool = false) -> URL {
        // Get the suite name
        let suiteName = String(describing: Self.self)

        // Extract file name from fileID
        // fileID format: "SwiftGitXTests/Collections/BranchCollectionTests.swift"
        let fileName = fileID.components(separatedBy: "/").last!.replacing(".swift", with: "")

        // Extract function name
        // function format: "testBranchLookup()" or "branchLookup()"
        let functionName = function.replacing("()", with: "").replacing("test", with: "")

        // Create the directory
        let directory = URL.temporaryDirectory
            .appending(components: "SwiftGitXTests", fileName, suiteName, functionName)

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

    init() throws {
        try SwiftGitXRuntime.initialize()
    }

    deinit {
        _ = try? SwiftGitXRuntime.shutdown()
    }
}

// Test the SwiftGitX struct to initialize and shutdown the library
@Suite("SwiftGitX Tests", .tags(.swiftGitX), .serialized)
struct SwiftGitXTests {
    @Test("Test SwiftGitX Initialize")
    func testSwiftGitXInitialize() async throws {
        // Initialize the SwiftGitX library
        let count = try SwiftGitXRuntime.initialize()

        // Check if the initialization count is valid
        #expect(count > 0)
    }

    @Test("Test SwiftGitX Shutdown")
    func testSwiftGitXShutdown() async throws {
        // Shutdown the SwiftGitX library
        let count = try SwiftGitXRuntime.shutdown()

        // Check if the shutdown count is valid
        #expect(count >= 0)
    }

    @Test("Test SwiftGitX Shutdown Without Calling Initialize")
    func testSwiftGitXShutdownWithoutInitialize() async throws {
        // Shutdown the SwiftGitX library
        let result = #expect(throws: SwiftGitXError.self) {
            try SwiftGitXRuntime.shutdown()
        }

        let error = try #require(result)

        // Check if the error is a SwiftGitXError
        #expect(error.code == .error)

        // Note: This is a quirk of libgit2's design. When shutdown() is called before initialize(),
        // it decrements the initialization count below 0 and returns a negative status code (error),
        // but git_error_last() returns no actual error object because libgit2 doesn't set one for
        // this particular case. Hence we get error code .error, but category .none and message "no error".
        //
        // We still throw an error because shutdown should not be called without initialize, even though
        // the error message is uninformative. This error can be ignored if needed.
        #expect(error.category == .none)
        #expect(error.message == "no error")
    }

    @Test("Test SwiftGitX Version")
    func testVersion() throws {
        // Get the libgit2 version
        let version = SwiftGitXRuntime.libgit2Version

        // Check if the version is valid
        #expect(version == "1.9.0")
    }
}

extension Testing.Tag {
    @Tag static var swiftGitX: Self
}
