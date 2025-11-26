import Foundation
import SwiftGitX
import Testing

@Suite("Reference Collection", .tags(.reference, .collection))
final class ReferenceCollectionTests: SwiftGitXTest {
    @Test("Lookup reference by name using subscript")
    func referenceLookupSubscript() async throws {
        let repository = mockRepository()

        // Create mock commit
        let commit = try repository.mockCommit()

        // Get the branch
        let reference = try #require(repository.reference["refs/heads/main"])

        // Check the reference
        #expect(reference.name == "main")
        #expect(reference.fullName == "refs/heads/main")
        #expect(reference.target.id == commit.id)
    }

    @Test("Lookup non-existent reference using subscript returns nil")
    func referenceLookupSubscriptFailure() async throws {
        let repository = mockRepository()

        // Create mock commit
        try repository.mockCommit()

        // Get the branch
        let reference = repository.reference["refs/heads/feature"]

        // Check the reference
        #expect(reference == nil)
    }

    @Test("Lookup branch reference")
    func referenceLookupBranch() async throws {
        let repository = mockRepository()

        // Create mock commit
        let commit = try repository.mockCommit()

        // Create a new branch
        let branch = try repository.branch.create(named: "feature", target: commit)

        // Get the branch
        let reference = try repository.reference.get(named: branch.fullName)

        // Check the reference
        #expect(reference.name == branch.name)
        #expect(reference.fullName == branch.fullName)
        #expect(reference.target.id == commit.id)
    }

    @Test("Lookup annotated tag reference")
    func referenceLookupTagAnnotated() async throws {
        let repository = mockRepository()

        // Create mock commit
        let commit = try repository.mockCommit()

        // Create a new tag
        let tag = try repository.tag.create(named: "v1.0.0", target: commit)

        // Get the tag
        let reference = try repository.reference.get(named: tag.fullName)

        // Check the reference
        #expect(reference.name == "v1.0.0")
        #expect(reference.fullName == "refs/tags/v1.0.0")
        #expect(reference.target.id == commit.id)
    }

    @Test("Lookup lightweight tag reference")
    func referenceLookupTagLightweight() async throws {
        let repository = mockRepository()

        // Create mock commit
        let commit = try repository.mockCommit()

        // Create a new tag
        let tag = try repository.tag.create(named: "v1.0.0", target: commit, type: .lightweight)

        // Get the tag
        let reference = try repository.reference.get(named: tag.fullName)

        // Check the reference
        #expect(reference.name == "v1.0.0")
        #expect(reference.fullName == "refs/tags/v1.0.0")
        #expect(reference.target.id == commit.id)
    }

    @Test("Lookup non-existent reference throws error")
    func referenceLookupFailure() async throws {
        let repository = mockRepository()

        // Create mock commit
        try repository.mockCommit()

        // Get the branch and verify error details
        #expect(throws: SwiftGitXError.self) {
            try repository.reference.get(named: "refs/heads/feature")
        }
    }

    @Test("List all references")
    func referenceList() async throws {
        let repository = mockRepository()

        // Create mock commit
        let commit = try repository.mockCommit()

        // Create a new branch
        try repository.branch.create(named: "feature", target: commit)

        // Create a new tag
        try repository.tag.create(named: "v1.0.0", target: commit)

        // Get the references
        let references = try repository.reference.list()

        // Check the reference
        #expect(references.count == 3)

        let referenceNames = references.map(\.name)
        #expect(referenceNames.contains("feature"))
        #expect(referenceNames.contains("main"))
        #expect(referenceNames.contains("v1.0.0"))
    }

    @Test("Iterate over all references")
    func referenceIterator() async throws {
        let repository = mockRepository()

        // Create mock commit
        let commit = try repository.mockCommit()

        // Create a new branch
        try repository.branch.create(named: "feature", target: commit)

        // Create a new tag
        try repository.tag.create(named: "v1.0.0", target: commit)

        // Get the references from iterator
        let references = Array(repository.reference)

        // Check the reference
        #expect(references.count == 3)

        let referenceNames = references.map(\.name)
        #expect(referenceNames.contains("feature"))
        #expect(referenceNames.contains("main"))
        #expect(referenceNames.contains("v1.0.0"))
    }

    @Test("List references with glob pattern")
    func referenceIteratorGlob() async throws {
        let repository = mockRepository()

        // Create mock commit
        let commit = try repository.mockCommit()

        // Create a new tag
        let tag = try repository.tag.create(named: "v1.0.0", target: commit)

        // Get the references from iterator
        let references = try repository.reference.list(glob: "refs/tags/*")

        // Check the references
        #expect(references.count == 1)

        let tagLookup = try #require(references.first as? SwiftGitX.Tag)

        #expect(tagLookup == tag)
    }
}

// MARK: - Tag Extensions

extension Testing.Tag {
    @Tag static var reference: Self
}
