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
        XCTAssertNoThrow(try SwiftGitX.initialize())
    }

    override class func tearDown() {
        // Shutdown the SwiftGitX library
        XCTAssertNoThrow(try SwiftGitX.shutdown())

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

    init() throws {
        try SwiftGitX.initialize()
    }

    deinit {
        _ = try? SwiftGitX.shutdown()
    }
}

// Test the SwiftGitX struct to initialize and shutdown the library
@Suite("SwiftGitX Tests", .tags(.swiftGitX), .serialized)
struct SwiftGitXTests {
    @Test("Test SwiftGitX Initialize")
    func testSwiftGitXInitialize() async throws {
        // Initialize the SwiftGitX library
        let count = try SwiftGitX.initialize()

        // Check if the initialization count is valid
        #expect(count > 0)
    }

    @Test("Test SwiftGitX Shutdown")
    func testSwiftGitXShutdown() async throws {
        // Shutdown the SwiftGitX library
        let count = try SwiftGitX.shutdown()

        // Check if the shutdown count is valid
        #expect(count >= 0)
    }

    @Test("Test SwiftGitX Version")
    func testVersion() throws {
        // Get the libgit2 version
        let version = SwiftGitX.libgit2Version

        // Check if the version is valid
        #expect(version == "1.9.0")
    }
}

extension Testing.Tag {
    @Tag static var swiftGitX: Self
}
