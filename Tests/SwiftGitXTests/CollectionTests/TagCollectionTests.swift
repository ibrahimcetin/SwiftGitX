import SwiftGitX
import XCTest

class TagCollectionTests: SwiftGitXTestCase {
    func testTagLookupSubscript() throws {
        // Create a new repository at the temporary directory
        let repository = Repository.mock(named: "test-tag-lookup-subscript", in: Self.directory)

        // Create mock commit
        let commit = try repository.mockCommit()

        // Create a new tag
        try repository.tag.create(named: "v1.0.0", target: commit)

        // Lookup the tag by name
        let tag = try XCTUnwrap(repository.tag["v1.0.0"])

        // Check the tag properties
        XCTAssertEqual(tag.name, "v1.0.0")
        XCTAssertEqual(tag.fullName, "refs/tags/v1.0.0")

        // The tag target is the commit
        let tagTarget = try XCTUnwrap(tag.target as? Commit)
        XCTAssertEqual(tagTarget, commit)
    }

    func testTagLookupSubscriptFailure() throws {
        // Create a new repository at the temporary directory
        let repository = Repository.mock(named: "test-tag-lookup-subscript-failure", in: Self.directory)

        // Create mock commit
        try repository.mockCommit()

        XCTAssertNil(repository.tag["v1.0.0"])
    }

    func testTagLookupAnnotated() throws {
        // Create a new repository at the temporary directory
        let repository = Repository.mock(named: "test-tag-lookup-annotated", in: Self.directory)

        // Create mock commit
        let commit = try repository.mockCommit()

        // Create a new tag
        try repository.tag.create(named: "v1.0.0", target: commit, message: "Initial release")

        // Lookup the tag by name
        let annotatedTag = try repository.tag.get(named: "v1.0.0")

        // Check the tag properties
        XCTAssertEqual(annotatedTag.name, "v1.0.0")
        XCTAssertEqual(annotatedTag.fullName, "refs/tags/v1.0.0")

        // The tag target is the commit
        let tagTarget = try XCTUnwrap(annotatedTag.target as? Commit)
        XCTAssertEqual(tagTarget, commit)

        XCTAssertEqual(annotatedTag.message, "Initial release")
    }

    func testTagLookupLightweight() throws {
        // Create a new repository at the temporary directory
        let repository = Repository.mock(named: "test-tag-lookup-lightweight", in: Self.directory)

        // Create mock commit
        let commit = try repository.mockCommit()

        // Create a new tag
        try repository.tag.create(named: "v1.0.0", target: commit, type: .lightweight)

        // Lookup the tag by short name
        let lightweightTag = try repository.tag.get(named: "v1.0.0")

        // Check the tag properties
        XCTAssertEqual(lightweightTag.name, "v1.0.0")
        XCTAssertEqual(lightweightTag.fullName, "refs/tags/v1.0.0")

        // Check if the tag id is the same as the blob id
        XCTAssertEqual(lightweightTag.id, commit.id)
        XCTAssertEqual(lightweightTag.id, lightweightTag.target.id)

        // Lightweight tag target is the commit
        let lightweightTagTarget = try XCTUnwrap(lightweightTag.target as? Commit)
        XCTAssertEqual(lightweightTagTarget, commit)

        // Lightweight tag have no tagger and message
        XCTAssertNil(lightweightTag.tagger)
        XCTAssertNil(lightweightTag.message)
    }

    func testTagList() throws {
        // Create a new repository at the temporary directory
        let repository = Repository.mock(named: "test-tag-list", in: Self.directory)

        // Check if the tag list is empty
        XCTAssertTrue(try repository.tag.list().isEmpty)

        // Create mock commit
        let commit = try repository.mockCommit()

        // Create some tags
        let newTagNames = ["v1.0.0", "v1.0.1", "v1.0.2", "v1.0.3"]

        for name in newTagNames {
            try repository.tag.create(named: name, target: commit)
        }

        // List all tags
        let tags = try repository.tag.list()

        // Check if the tag is in the list
        XCTAssertEqual(tags.count, 4)

        for tag in tags {
            XCTAssertTrue(newTagNames.contains(tag.name))
        }
    }

    func testTagIterator() throws {
        // Create a new repository at the temporary directory
        let repository = Repository.mock(named: "test-tag-iterator", in: Self.directory)

        // Create mock commits
        let commits = try (0 ..< 5).map { index in
            try repository.mockCommit(file: repository.mockFile(named: "README-\(index).md"))
        }

        // Create some tags
        let newTagNames = ["v1.0.0", "v1.0.1", "v1.0.2", "v1.0.3", "v1.0.4"]

        for (name, commit) in zip(newTagNames, commits) {
            try repository.tag.create(named: name, target: commit, message: "Release \(name)")
        }

        // Iterate over the tags
        for (tag, commit) in zip(repository.tag, commits) {
            XCTAssertTrue(newTagNames.contains(tag.name))
            XCTAssertEqual("refs/tags/\(tag.name)", tag.fullName)
            XCTAssertEqual(tag.target as? Commit, commit)
            XCTAssertEqual(tag.message, "Release \(tag.name)")
        }
    }

    func testTagCreateAnnotated() throws {
        // Create mock repository at the temporary directory
        let repository = Repository.mock(named: "test-tag-create-annotated", in: Self.directory)

        // Commit the changes
        let commit = try repository.mockCommit()

        // Create a new tag
        let annotatedTag = try repository.tag.create(named: "v1.0.0", target: repository.HEAD.target)

        // Check the tag properties
        XCTAssertEqual(annotatedTag.name, "v1.0.0")
        XCTAssertEqual(annotatedTag.fullName, "refs/tags/v1.0.0")

        // The tag target is the commit
        let tagTarget = try XCTUnwrap(annotatedTag.target as? Commit)
        XCTAssertEqual(tagTarget, commit)

        XCTAssertNil(annotatedTag.message)
    }

    func testTagCreateLightweight() throws {
        // Create mock repository at the temporary directory
        let repository = Repository.mock(named: "test-tag-create-lightweight", in: Self.directory)

        // Commit the changes
        let commit = try repository.mockCommit()

        // Create a new tag
        let lightweightTag = try repository.tag.create(named: "v1.0.0", target: commit, type: .lightweight)

        // Check the name of the tag
        XCTAssertEqual(lightweightTag.name, "v1.0.0")
        XCTAssertEqual(lightweightTag.fullName, "refs/tags/v1.0.0")

        // Lightweight tag have the same id as the target commit
        XCTAssertEqual(lightweightTag.id, commit.id)
        XCTAssertEqual(lightweightTag.id, lightweightTag.target.id)

        // Lightweight tag target is the commit
        let lightweightTagTarget = try XCTUnwrap(lightweightTag.target as? Commit)
        XCTAssertEqual(lightweightTagTarget, commit)

        // Lightweight tag have no tagger and message
        XCTAssertNil(lightweightTag.tagger)
        XCTAssertNil(lightweightTag.message)
    }

    func testTagCreateLightweightPointingTree() throws {
        // Create mock repository at the temporary directory
        let repository = Repository.mock(named: "test-tag-create-lightweight-pointing-tree", in: Self.directory)

        // Create mock commit
        let commit = try repository.mockCommit()

        // Get the tree of the commit
        let tree = commit.tree

        // Create a new tag
        let lightweightTag = try repository.tag.create(named: "v1.0.0", target: tree, type: .lightweight)

        // Check the name of the tag
        XCTAssertEqual(lightweightTag.name, "v1.0.0")
        XCTAssertEqual(lightweightTag.fullName, "refs/tags/v1.0.0")

        // Check if the tag id is the same as the tree id
        XCTAssertEqual(lightweightTag.id, tree.id)
        XCTAssertEqual(lightweightTag.id, lightweightTag.target.id)

        // Lightweight tag target is the tree
        let lightweightTagTarget = try XCTUnwrap(lightweightTag.target as? Tree)
        XCTAssertEqual(lightweightTagTarget, tree)

        // Lightweight tag have no tagger and message
        XCTAssertNil(lightweightTag.tagger)
        XCTAssertNil(lightweightTag.message)
    }

    func testTagCreateLightweightPointingBlob() throws {
        // Create mock repository at the temporary directory
        let repository = Repository.mock(named: "test-tag-create-lightweight-pointing-blob", in: Self.directory)

        // Create mock commit
        let commit = try repository.mockCommit()

        // Get the first blob from the commit
        let blob: Blob = commit.tree.entries.compactMap {
            let this: Blob? = try? repository.show(id: $0.id)
            return this
        }.first!

        // Create a new tag
        let lightweightTag = try repository.tag.create(named: "v1.0.0", target: blob, type: .lightweight)

        // Check the name of the tag
        XCTAssertEqual(lightweightTag.name, "v1.0.0")
        XCTAssertEqual(lightweightTag.fullName, "refs/tags/v1.0.0")

        // Check if the tag id is the same as the blob id
        XCTAssertEqual(lightweightTag.id, blob.id)
        XCTAssertEqual(lightweightTag.id, lightweightTag.target.id)

        // Lightweight tag target is the blob
        let lightweightTagTarget = try XCTUnwrap(lightweightTag.target as? Blob)
        XCTAssertEqual(lightweightTagTarget, blob)

        // Lightweight tag have no tagger and message
        XCTAssertNil(lightweightTag.tagger)
        XCTAssertNil(lightweightTag.message)
    }

    func testTagCreateLightweightPointingTag() throws {
        // Create mock repository at the temporary directory
        let repository = Repository.mock(named: "test-tag-create-lightweight-pointing-tag", in: Self.directory)

        // Create mock commit
        let commit = try repository.mockCommit()

        // Create a new tag
        let annotatedTag = try repository.tag.create(named: "initial-tag", target: commit)

        // Create a new tag
        let lightweightTag = try repository.tag.create(named: "v1.0.0", target: annotatedTag, type: .lightweight)

        // Check the name of the tag
        XCTAssertEqual(lightweightTag.name, "v1.0.0")
        XCTAssertEqual(lightweightTag.fullName, "refs/tags/v1.0.0")

        // Check if the tag id is the same as the blob id
        XCTAssertEqual(lightweightTag.id, annotatedTag.id)
        XCTAssertEqual(lightweightTag.id, lightweightTag.target.id)

        // Lightweight tag target is the annotated tag
        let lightweightTagTarget = try XCTUnwrap(lightweightTag.target as? Tag)
        XCTAssertEqual(lightweightTagTarget, annotatedTag)

        // Lightweight tag have no tagger and message
        XCTAssertNil(lightweightTag.tagger)
        XCTAssertNil(lightweightTag.message)
    }
}
