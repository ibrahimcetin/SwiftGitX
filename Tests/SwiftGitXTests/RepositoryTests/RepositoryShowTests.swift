import XCTest

@testable import SwiftGitX

final class RepositoryShowTests: SwiftGitXTestCase {
    func testShowCommit() throws {
        // Create mock repository at the temporary directory
        let repository = Repository.mock(named: "test-show-commit", in: Self.directory)

        // Create a new commit
        let commit = try repository.mockCommit()

        // Get the commit by id
        let commitShowed: Commit = try repository.show(id: commit.id)

        // Check if the commit is the same
        XCTAssertEqual(commit, commitShowed)
    }

    func testShowTag() throws {
        // Create mock repository at the temporary directory
        let repository = Repository.mock(named: "test-show-tag", in: Self.directory)

        // Create a new commit
        let commit = try repository.mockCommit()

        // Create a new tag
        let tag = try repository.tag.create(named: "v1.0.0", target: commit)

        // Get the tag by id
        let tagShowed: Tag = try repository.show(id: tag.id)

        // Check if the tag is the same
        XCTAssertEqual(tag, tagShowed)
    }

    func testShowTree() throws {
        // Create mock repository at the temporary directory
        let repository = Repository.mock(named: "test-show-tree", in: Self.directory)

        // Create a new commit
        let commit = try repository.mockCommit()

        // Get the tree of the commit
        let tree = try commit.tree

        // Get the tree by id
        let treeShowed: Tree = try repository.show(id: tree.id)

        // Check if the tree is the same
        XCTAssertEqual(tree, treeShowed)
    }

    func testShowBlob() throws {
        // Create mock repository at the temporary directory
        let repository = Repository.mock(named: "test-show-blob", in: Self.directory)

        // Create a new commit
        let commit = try repository.mockCommit()

        // Get the blob of the file
        let blob = try XCTUnwrap(commit.tree.entries.first)

        // Get the blob by id
        let blobShowed: Blob = try repository.show(id: blob.id)

        // Check if the blob properties are the same
        XCTAssertEqual(blob.id, blobShowed.id)
        XCTAssertEqual(blob.type, blobShowed.type)
    }

    func testShowInvalidObjectType() throws {
        // Create mock repository at the temporary directory
        let repository = Repository.mock(named: "test-show-invalid-object-type", in: Self.directory)

        // Create a new commit
        let commit = try repository.mockCommit()

        // Try to show a commit as a tree
        XCTAssertThrowsError(try repository.show(id: commit.id) as Tree)
    }
}
