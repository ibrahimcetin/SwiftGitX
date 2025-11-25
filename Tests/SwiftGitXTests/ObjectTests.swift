import XCTest
import libgit2

@testable import SwiftGitX

final class ObjectTests: SwiftGitXTestCase {
    func testOID() throws {
        // Test OID hex initialization
        let shaHex = "42a02b346bb0fb0db7eff3cffeb3c70babbd2045"
        let oid = try OID(hex: shaHex)

        // Check if the OID hex is correct
        XCTAssertEqual(oid.hex, shaHex)

        let raw = oid.raw
        XCTAssertEqual(oid, OID(raw: raw))
        XCTAssertEqual(oid.abbreviated, OID(raw: raw).abbreviated)
        XCTAssertEqual(oid.hex, OID(raw: raw).hex)

        // Check if the OID abbreviated is correct
        let abbreviatedSHA = "42a02b34"
        XCTAssertEqual(oid.abbreviated, abbreviatedSHA)

        // Check if the OID raw is correct
        var rawOID = git_oid()
        git_oid_fromstr(&rawOID, shaHex)

        XCTAssertEqual(oid, OID(raw: rawOID))

        // Test OID is zero
        let zeroOID = OID.zero

        XCTAssertEqual(zeroOID.hex, "0000000000000000000000000000000000000000")
        XCTAssertEqual(zeroOID.abbreviated, "00000000")

        var zeroOIDRaw = zeroOID.raw
        XCTAssertEqual(git_oid_is_zero(&zeroOIDRaw), 1)

        XCTAssertEqual(zeroOID, .zero)
    }

    func testCommit() throws {
        // Create mock repository at the temporary directory
        let repository = Repository.mock(named: "test-object-commit", in: Self.directory)

        // Create a new file in the repository
        let file = try repository.workingDirectory.appending(component: "README.md")
        FileManager.default.createFile(atPath: file.path, contents: nil)

        // Add the file to the index
        XCTAssertNoThrow(try repository.add(file: file))

        // Commit the changes
        let initialCommit = try repository.commit(message: "Initial commit")

        // TODO: Get default signature

        XCTAssertEqual(initialCommit.id, try repository.HEAD.target.id)
        XCTAssertEqual(initialCommit.message, "Initial commit")

        // Check if the commit has no parent
        XCTAssertEqual(try initialCommit.parents.count, 0)

        // Add content to the file
        try Data("Hello, World!".utf8).write(to: file)

        // Add the file to the index
        XCTAssertNoThrow(try repository.add(path: "README.md"))

        // Commit the changes
        let commit = try repository.commit(message: "Add content to README.md")

        // Check if the commit has the correct parent
        XCTAssertEqual(try commit.parents.count, 1)

        let parentCommit: Commit = try repository.show(id: commit.parents.first!.id)
        XCTAssertEqual(parentCommit, initialCommit)
    }

    func testTagAnnotated() throws {
        // Create a new repository at the temporary directory
        let repository = Repository.mock(named: "test-object-tag-annotated", in: Self.directory)

        // Commit the changes
        let commit = try repository.mockCommit()

        // Create a new tag
        let tag = try repository.tag.create(
            named: "v1.0.0", target: commit, message: "Initial release"
        )

        // Check if the tag is the same
        XCTAssertEqual(tag.name, "v1.0.0")
        XCTAssertEqual(tag.fullName, "refs/tags/v1.0.0")

        XCTAssertEqual(tag.target.id, commit.id)
        XCTAssertEqual(tag.message, "Initial release")

        // TODO: Check tagger signature
    }

    func testTagLightweight() throws {
        // Create a new repository at the temporary directory
        let repository = Repository.mock(named: "test-object-tag-lightweight", in: Self.directory)

        // Commit the changes
        let commit = try repository.mockCommit()

        // Create a new tag
        let tag = try repository.tag.create(named: "v1.0.0", target: commit, type: .lightweight)

        // Check the tag properties
        XCTAssertEqual(tag.name, "v1.0.0")
        XCTAssertEqual(tag.fullName, "refs/tags/v1.0.0")

        XCTAssertEqual(tag.id, commit.id)
        XCTAssertEqual(tag.id, tag.target.id)
        XCTAssertEqual(tag.target.id, commit.id)

        XCTAssertNil(tag.tagger)
        XCTAssertNil(tag.message)
    }
}
