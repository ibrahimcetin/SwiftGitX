import SwiftGitX
import Testing

// MARK: - Lookup Operations

@Suite("Tag Collection - Lookup Operations", .tags(.tag, .collection))
final class TagLookupTests: SwiftGitXTest {
    @Test("Lookup tag by subscript")
    func lookupSubscript() async throws {
        let repository = mockRepository()
        let commit = try repository.mockCommit()

        // Create a tag
        try repository.tag.create(named: "v1.0.0", target: commit)

        // Lookup by subscript
        let tag = try #require(repository.tag["v1.0.0"])

        #expect(tag.name == "v1.0.0")
        #expect(tag.fullName == "refs/tags/v1.0.0")

        // Tag target is the commit
        let tagTarget = try #require(tag.target as? Commit)
        #expect(tagTarget == commit)
    }

    @Test("Lookup non-existent tag returns nil")
    func lookupSubscriptNotFound() async throws {
        let repository = mockRepository()
        try repository.mockCommit()

        #expect(repository.tag["v1.0.0"] == nil)
    }

    @Test("Get annotated tag")
    func getAnnotated() async throws {
        let repository = mockRepository()
        let commit = try repository.mockCommit()

        // Create annotated tag with message
        try repository.tag.create(named: "v1.0.0", target: commit, message: "Initial release")

        // Lookup the tag
        let annotatedTag = try repository.tag.get(named: "v1.0.0")

        #expect(annotatedTag.name == "v1.0.0")
        #expect(annotatedTag.fullName == "refs/tags/v1.0.0")
        #expect(annotatedTag.message == "Initial release")

        // Tag target is the commit
        let tagTarget = try #require(annotatedTag.target as? Commit)
        #expect(tagTarget == commit)
    }

    @Test("Get lightweight tag")
    func getLightweight() async throws {
        let repository = mockRepository()
        let commit = try repository.mockCommit()

        // Create lightweight tag
        try repository.tag.create(named: "v1.0.0", target: commit, type: .lightweight)

        // Lookup the tag
        let lightweightTag = try repository.tag.get(named: "v1.0.0")

        #expect(lightweightTag.name == "v1.0.0")
        #expect(lightweightTag.fullName == "refs/tags/v1.0.0")

        // Lightweight tag ID matches commit ID
        #expect(lightweightTag.id == commit.id)
        #expect(lightweightTag.id == lightweightTag.target.id)

        // Tag target is the commit
        let lightweightTagTarget = try #require(lightweightTag.target as? Commit)
        #expect(lightweightTagTarget == commit)

        // Lightweight tags have no tagger or message
        #expect(lightweightTag.tagger == nil)
        #expect(lightweightTag.message == nil)
    }

    @Test("Get non-existent tag throws error", .tags(.error))
    func getNotFoundThrows() async throws {
        let repository = mockRepository()
        try repository.mockCommit()

        #expect(throws: SwiftGitXError.self) {
            try repository.tag.get(named: "non-existent")
        }
    }
}

// MARK: - List & Iterator Operations

@Suite("Tag Collection - List & Iterator", .tags(.tag, .collection))
final class TagListTests: SwiftGitXTest {
    @Test("List returns empty array when no tags exist")
    func listEmpty() async throws {
        let repository = mockRepository()
        try repository.mockCommit()

        let tags = try repository.tag.list()
        #expect(tags.isEmpty)
    }

    @Test("List returns all tags")
    func listAll() async throws {
        let repository = mockRepository()
        let commit = try repository.mockCommit()

        // Create tags
        let tagNames = ["v1.0.0", "v1.0.1", "v1.0.2", "v1.0.3"]
        for name in tagNames {
            try repository.tag.create(named: name, target: commit)
        }

        // List all tags
        let tags = try repository.tag.list()

        #expect(tags.count == 4)
        for tag in tags {
            #expect(tagNames.contains(tag.name))
        }
    }

    @Test("Iterate over tags")
    func iterate() async throws {
        let repository = mockRepository()

        // Create commits and tags
        let commits = try (0..<5).map { _ in
            try repository.mockCommit(file: repository.mockFile())
        }

        let tagNames = ["v1.0.0", "v1.0.1", "v1.0.2", "v1.0.3", "v1.0.4"]
        for (name, commit) in zip(tagNames, commits) {
            try repository.tag.create(named: name, target: commit, message: "Release \(name)")
        }

        // Iterate over tags
        for (tag, commit) in zip(repository.tag, commits) {
            #expect(tagNames.contains(tag.name))
            #expect(tag.fullName == "refs/tags/\(tag.name)")
            #expect(tag.target as? Commit == commit)
            #expect(tag.message == "Release \(tag.name)")
        }
    }
}

// MARK: - Create Operations

@Suite("Tag Collection - Create Operations", .tags(.tag, .collection))
final class TagCreateTests: SwiftGitXTest {
    @Test("Create annotated tag")
    func createAnnotated() async throws {
        let repository = mockRepository()
        let commit = try repository.mockCommit()

        // Create annotated tag (default type)
        let annotatedTag = try repository.tag.create(named: "v1.0.0", target: repository.HEAD.target)

        #expect(annotatedTag.name == "v1.0.0")
        #expect(annotatedTag.fullName == "refs/tags/v1.0.0")
        #expect(annotatedTag.target.id == commit.id)
        #expect(annotatedTag.message == nil)

        // Tag target is the commit
        let tagTarget = try #require(annotatedTag.target as? Commit)
        #expect(tagTarget == commit)
    }

    @Test("Create lightweight tag")
    func createLightweight() async throws {
        let repository = mockRepository()
        let commit = try repository.mockCommit()

        // Create lightweight tag
        let lightweightTag = try repository.tag.create(named: "v1.0.0", target: commit, type: .lightweight)

        #expect(lightweightTag.name == "v1.0.0")
        #expect(lightweightTag.fullName == "refs/tags/v1.0.0")
        #expect(lightweightTag.target.id == commit.id)

        // Lightweight tag has same ID as commit
        #expect(lightweightTag.id == commit.id)
        #expect(lightweightTag.id == lightweightTag.target.id)

        // Tag target is the commit
        let lightweightTagTarget = try #require(lightweightTag.target as? Commit)
        #expect(lightweightTagTarget == commit)

        // Lightweight tags have no tagger or message
        #expect(lightweightTag.tagger == nil)
        #expect(lightweightTag.message == nil)
    }

    @Test("Create lightweight tag pointing to tree")
    func createLightweightPointingTree() async throws {
        let repository = mockRepository()
        let commit = try repository.mockCommit()

        // Get tree from commit
        let tree = try commit.tree

        // Create lightweight tag pointing to tree
        let lightweightTag = try repository.tag.create(named: "v1.0.0", target: tree, type: .lightweight)

        #expect(lightweightTag.name == "v1.0.0")
        #expect(lightweightTag.fullName == "refs/tags/v1.0.0")
        #expect(lightweightTag.target.id == tree.id)

        // Tag ID matches tree ID
        #expect(lightweightTag.id == tree.id)
        #expect(lightweightTag.id == lightweightTag.target.id)

        // Tag target is the tree
        let lightweightTagTarget = try #require(lightweightTag.target as? Tree)
        #expect(lightweightTagTarget == tree)

        // Lightweight tags have no tagger or message
        #expect(lightweightTag.tagger == nil)
        #expect(lightweightTag.message == nil)
    }

    @Test("Create lightweight tag pointing to blob")
    func createLightweightPointingBlob() async throws {
        let repository = mockRepository()
        let commit = try repository.mockCommit()

        // Get first blob from commit's tree
        let tree = try commit.tree
        let blob: Blob = try #require(
            tree.entries.compactMap { (entry) -> Blob? in try? repository.show(id: entry.id) }.first
        )

        // Create lightweight tag pointing to blob
        let lightweightTag = try repository.tag.create(named: "v1.0.0", target: blob, type: .lightweight)

        #expect(lightweightTag.name == "v1.0.0")
        #expect(lightweightTag.fullName == "refs/tags/v1.0.0")
        #expect(lightweightTag.target.id == blob.id)

        // Tag ID matches blob ID
        #expect(lightweightTag.id == blob.id)
        #expect(lightweightTag.id == lightweightTag.target.id)

        // Tag target is the blob
        let lightweightTagTarget = try #require(lightweightTag.target as? Blob)
        #expect(lightweightTagTarget == blob)

        // Lightweight tags have no tagger or message
        #expect(lightweightTag.tagger == nil)
        #expect(lightweightTag.message == nil)
    }

    @Test("Create lightweight tag pointing to tag")
    func createLightweightPointingTag() async throws {
        let repository = mockRepository()
        let commit = try repository.mockCommit()

        // Create an annotated tag first
        let annotatedTag = try repository.tag.create(named: "initial-tag", target: commit)

        // Create lightweight tag pointing to the annotated tag
        let lightweightTag = try repository.tag.create(named: "v1.0.0", target: annotatedTag, type: .lightweight)

        #expect(lightweightTag.name == "v1.0.0")
        #expect(lightweightTag.fullName == "refs/tags/v1.0.0")
        #expect(lightweightTag.target.id == annotatedTag.id)

        // Tag ID matches annotated tag ID
        #expect(lightweightTag.id == annotatedTag.id)
        #expect(lightweightTag.id == lightweightTag.target.id)

        // Tag target is the annotated tag
        let lightweightTagTarget = try #require(lightweightTag.target as? SwiftGitX.Tag)
        #expect(lightweightTagTarget == annotatedTag)

        // Lightweight tags have no tagger or message
        #expect(lightweightTag.tagger == nil)
        #expect(lightweightTag.message == nil)
    }

    @Test("Create annotated tag with message")
    func createAnnotatedWithMessage() async throws {
        let repository = mockRepository()
        let commit = try repository.mockCommit()

        // Create annotated tag with message
        let tag = try repository.tag.create(
            named: "v1.0.0",
            target: commit,
            message: "Release version 1.0.0"
        )

        #expect(tag.name == "v1.0.0")
        #expect(tag.fullName == "refs/tags/v1.0.0")
        #expect(tag.target.id == commit.id)
        #expect(tag.message == "Release version 1.0.0")
        #expect(tag.tagger != nil)
    }

    @Test("Create annotated tag with custom tagger")
    func createAnnotatedWithCustomTagger() async throws {
        let repository = mockRepository()
        let commit = try repository.mockCommit()

        // Create custom tagger signature
        let customTagger = Signature(
            name: "Custom Tagger",
            email: "tagger@example.com"
        )

        // Create annotated tag with custom tagger
        let tag = try repository.tag.create(
            named: "v1.0.0",
            target: commit,
            tagger: customTagger,
            message: "Tagged by custom tagger"
        )

        #expect(tag.name == "v1.0.0")
        #expect(tag.message == "Tagged by custom tagger")
        #expect(tag.target.id == commit.id)

        let tagger = try #require(tag.tagger)
        #expect(tagger.name == "Custom Tagger")
        #expect(tagger.email == "tagger@example.com")
    }

    @Test("Create tag with force overwrites existing")
    func createWithForceOverwrites() async throws {
        let repository = mockRepository()
        let commit1 = try repository.mockCommit()
        let commit2 = try repository.mockCommit()

        // Create initial tag
        let originalTag = try repository.tag.create(named: "v1.0.0", target: commit1, message: "Original")
        #expect(originalTag.message == "Original")
        #expect(originalTag.target.id == commit1.id)

        // Overwrite with force
        let newTag = try repository.tag.create(
            named: "v1.0.0",
            target: commit2,
            message: "Overwritten",
            force: true
        )

        #expect(newTag.name == "v1.0.0")
        #expect(newTag.message == "Overwritten")
        #expect(newTag.target.id == commit2.id)

        // Verify the tag now points to commit2
        let tagTarget = try #require(newTag.target as? Commit)
        #expect(tagTarget == commit2)
    }

    @Test("Create existing tag without force throws error", .tags(.error))
    func createExistingTagThrows() async throws {
        let repository = mockRepository()
        let commit = try repository.mockCommit()

        // Create initial tag
        try repository.tag.create(named: "v1.0.0", target: commit)

        // Try to create again without force
        #expect(throws: SwiftGitXError.self) {
            try repository.tag.create(named: "v1.0.0", target: commit)
        }
    }
}
