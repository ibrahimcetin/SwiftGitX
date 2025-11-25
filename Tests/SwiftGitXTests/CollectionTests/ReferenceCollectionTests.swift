import SwiftGitX
import XCTest

final class ReferenceCollectionTests: SwiftGitXTestCase {
    func testReferenceLookupSubscript() throws {
        // Create a new repository at the temporary directory
        let repository = Repository.mock(named: "test-reference-lookup-subscript", in: Self.directory)

        // Create mock commit
        let commit = try repository.mockCommit()

        // Get the branch
        guard let reference = repository.reference["refs/heads/main"] else {
            XCTFail("Reference not found")
            return
        }

        // Check the reference
        XCTAssertEqual(reference.name, "main")
        XCTAssertEqual(reference.fullName, "refs/heads/main")
        XCTAssertEqual(reference.target.id, commit.id)
    }

    func testReferenceLookupSubscriptFailure() throws {
        // Create a new repository at the temporary directory
        let repository = Repository.mock(named: "test-reference-lookup-subscript-failure", in: Self.directory)

        // Create mock commit
        try repository.mockCommit()

        // Get the branch
        let reference = repository.reference["refs/heads/feature"]

        // Check the reference
        XCTAssertNil(reference)
    }

    func testReferenceLookupBranch() throws {
        // Create a new repository at the temporary directory
        let repository = Repository.mock(named: "test-reference-lookup-branch", in: Self.directory)

        // Create mock commit
        let commit = try repository.mockCommit()

        // Create a new branch
        let branch = try repository.branch.create(named: "feature", target: commit)

        // Get the branch
        let reference = try repository.reference.get(named: branch.fullName)

        // Check the reference
        XCTAssertEqual(reference.name, branch.name)
        XCTAssertEqual(reference.fullName, branch.fullName)
        XCTAssertEqual(reference.target.id, commit.id)
    }

    func testReferenceLookupTagAnnotated() throws {
        // Create a new repository at the temporary directory
        let repository = Repository.mock(named: "test-reference-lookup-tag-annotated", in: Self.directory)

        // Create mock commit
        let commit = try repository.mockCommit()

        // Create a new tag
        let tag = try repository.tag.create(named: "v1.0.0", target: commit)

        // Get the tag
        let reference = try repository.reference.get(named: tag.fullName)

        // Check the reference
        XCTAssertEqual(reference.name, "v1.0.0")
        XCTAssertEqual(reference.fullName, "refs/tags/v1.0.0")
        XCTAssertEqual(reference.target.id, commit.id)
    }

    func testReferenceLookupTagLightweight() throws {
        // Create a new repository at the temporary directory
        let repository = Repository.mock(named: "test-reference-lookup-tag-lightweight", in: Self.directory)

        // Create mock commit
        let commit = try repository.mockCommit()

        // Create a new tag
        let tag = try repository.tag.create(named: "v1.0.0", target: commit, type: .lightweight)

        // Get the tag
        let reference = try repository.reference.get(named: tag.fullName)

        // Check the reference
        XCTAssertEqual(reference.name, "v1.0.0")
        XCTAssertEqual(reference.fullName, "refs/tags/v1.0.0")
        XCTAssertEqual(reference.target.id, commit.id)
    }

    func testReferenceLookupFailure() throws {
        // Create a new repository at the temporary directory
        let repository = Repository.mock(named: "test-reference-lookup-failure", in: Self.directory)

        // Create mock commit
        try repository.mockCommit()

        // Get the branch
        XCTAssertThrowsError(try repository.reference.get(named: "refs/heads/feature")) { error in
            XCTAssertTrue(error is SwiftGitXError)
            let error = error as? SwiftGitXError

            XCTAssertEqual(error?.code, .notFound)
            XCTAssertEqual(error?.category, .reference)
            XCTAssertEqual(error?.message, "reference \'refs/heads/feature\' not found")
        }
    }

    func testReferenceList() throws {
        // Create a new repository at the temporary directory
        let repository = Repository.mock(named: "test-reference-list", in: Self.directory)

        // Create mock commit
        let commit = try repository.mockCommit()

        // Create a new branch
        try repository.branch.create(named: "feature", target: commit)

        // Create a new tag
        try repository.tag.create(named: "v1.0.0", target: commit)

        // Get the references
        let references = try repository.reference.list()

        // Check the reference
        XCTAssertEqual(references.count, 3)

        let referenceNames = references.map(\.name)
        XCTAssertTrue(referenceNames.contains("feature"))
        XCTAssertTrue(referenceNames.contains("main"))
        XCTAssertTrue(referenceNames.contains("v1.0.0"))
    }

    func testReferenceIterator() throws {
        // Create a new repository at the temporary directory
        let repository = Repository.mock(named: "test-reference-iterator", in: Self.directory)

        // Create mock commit
        let commit = try repository.mockCommit()

        // Create a new branch
        try repository.branch.create(named: "feature", target: commit)

        // Create a new tag
        try repository.tag.create(named: "v1.0.0", target: commit)

        // Get the references from iterator
        let references = Array(repository.reference)

        // Check the reference
        XCTAssertEqual(references.count, 3)

        let referenceNames = references.map(\.name)
        XCTAssertTrue(referenceNames.contains("feature"))
        XCTAssertTrue(referenceNames.contains("main"))
        XCTAssertTrue(referenceNames.contains("v1.0.0"))
    }

    func testReferenceIteratorGlob() throws {
        // Create a new repository at the temporary directory
        let repository = Repository.mock(named: "test-reference-iterator-glob", in: Self.directory)

        // Create mock commit
        let commit = try repository.mockCommit()

        // Create a new tag
        let tag = try repository.tag.create(named: "v1.0.0", target: commit)

        // Get the references from iterator
        let references = try repository.reference.list(glob: "refs/tags/*")

        // Check the references
        XCTAssertEqual(references.count, 1)
        let tagLookup = try XCTUnwrap(references.first as? Tag)

        XCTAssertEqual(tagLookup, tag)
    }
}
