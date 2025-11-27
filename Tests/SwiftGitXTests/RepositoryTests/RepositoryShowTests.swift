import SwiftGitX
import Testing

@Suite("Repository - Show", .tags(.repository, .operation, .show))
final class RepositoryShowTests: SwiftGitXTest {
    @Test("Show Commit")
    func showCommit() throws {
        // Create mock repository at the temporary directory
        let repository = mockRepository()

        // Create a new commit
        let commit = try repository.mockCommit()

        // Get the commit by id
        let commitShowed: Commit = try repository.show(id: commit.id)

        // Check if the commit is the same
        #expect(commit == commitShowed)
    }

    @Test("Show Tag")
    func showTag() throws {
        // Create mock repository at the temporary directory
        let repository = mockRepository()

        // Create a new commit
        let commit = try repository.mockCommit()

        // Create a new tag
        let tag = try repository.tag.create(named: "v1.0.0", target: commit)

        // Get the tag by id
        let tagShowed: SwiftGitX.Tag = try repository.show(id: tag.id)

        // Check if the tag is the same
        #expect(tag == tagShowed)
    }

    @Test("Show Tree")
    func showTree() throws {
        // Create mock repository at the temporary directory
        let repository = mockRepository()

        // Create a new commit
        let commit = try repository.mockCommit()

        // Get the tree of the commit
        let tree = try commit.tree

        // Get the tree by id
        let treeShowed: Tree = try repository.show(id: tree.id)

        // Check if the tree is the same
        #expect(tree == treeShowed)
    }

    @Test("Show Blob")
    func showBlob() throws {
        // Create mock repository at the temporary directory
        let repository = mockRepository()

        // Create a new commit
        let commit = try repository.mockCommit()

        // Get the blob of the file
        let blob = try #require(commit.tree.entries.first)

        // Get the blob by id
        let blobShowed: Blob = try repository.show(id: blob.id)

        // Check if the blob properties are the same
        #expect(blob.id == blobShowed.id)
        #expect(blob.type == blobShowed.type)
    }

    @Test("Show Invalid Object Type Should Fail")
    func showInvalidObjectType() throws {
        // Create mock repository at the temporary directory
        let repository = mockRepository()

        // Create a new commit
        let commit = try repository.mockCommit()

        // Try to show a commit as a tree
        #expect(throws: Error.self) {
            try repository.show(id: commit.id) as Tree
        }
    }
}
