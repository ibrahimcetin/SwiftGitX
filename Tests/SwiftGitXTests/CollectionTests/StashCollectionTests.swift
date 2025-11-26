import Foundation
import SwiftGitX
import Testing

@Suite("Stash Collection", .tags(.stash, .collection))
final class StashCollectionTests: SwiftGitXTest {
    @Test("Save changes to stash")
    func stashSave() async throws {
        let repository = mockRepository()

        // Create mock commit
        try repository.mockCommit()

        // Create a file
        let file2 = try repository.mockFile()

        // Stage the file
        try repository.add(file: file2)

        // Create a new stash entry
        try repository.stash.save()

        // List the stash entries
        let stashes = try repository.stash.list()

        // Check the stash entries
        #expect(stashes.count == 1)
    }

    @Test("Save with nothing to stash throws error")
    func stashSaveFailure() async throws {
        let repository = mockRepository()
        try repository.mockCommit()

        // Create a new stash entry (should throw)
        let error = #expect(throws: SwiftGitXError.self) {
            try repository.stash.save()
        }

        #expect(error?.code == .notFound)
        #expect(error?.category == .stash)
        #expect(error?.message == "cannot stash changes - there is nothing to stash.")
    }

    @Test("Include untracked files in stash")
    func stashIncludeUntracked() async throws {
        let repository = mockRepository()
        try repository.mockCommit()

        for index in 0..<5 {
            // Create a file
            _ = try repository.mockFile()

            // Create a new stash
            try repository.stash.save(message: "Stashed \(index)!", options: .includeUntracked)
        }

        // List the stash entries
        let stashes = try repository.stash.list()

        // Check the stash entries
        #expect(stashes.count == 5)
    }

    @Test("Iterate over stash entries")
    func stashIterator() async throws {
        let repository = mockRepository()
        try repository.mockCommit()

        for index in 0..<5 {
            // Create a file
            _ = try repository.mockFile()

            // Create a new stash
            try repository.stash.save(message: "Stashed \(index)!", options: .includeUntracked)
        }

        // Iterate over the stash entries
        for (index, entry) in repository.stash.enumerated() {
            #expect(entry.index == index)
            #expect(entry.message == "On main: Stashed \(4 - index)!")
        }
    }

    @Test("Apply stash keeps stash entry")
    func stashApply() async throws {
        let repository = mockRepository()
        try repository.mockCommit()

        // Create a file
        let file2 = try repository.mockFile()

        // Create a new stash entry
        try repository.stash.save(options: .includeUntracked)

        #expect(try repository.stash.list().count == 1)
        #expect(FileManager.default.fileExists(atPath: file2.path) == false)

        // Apply the stash entry
        try repository.stash.apply()

        // List the stashes
        let stashes = try repository.stash.list()

        // Check the stash entries
        #expect(stashes.count == 1)  // The stash should still exist
        #expect(FileManager.default.fileExists(atPath: file2.path) == true)
        #expect(try String(contentsOf: file2) == "File 2 content\n")
    }

    @Test("Pop stash removes stash entry")
    func stashPop() async throws {
        let repository = mockRepository()
        try repository.mockCommit()

        // Create a file
        let file2 = try repository.mockFile()

        // Create a new stash entry
        try repository.stash.save(options: .includeUntracked)

        #expect(try repository.stash.list().count == 1)
        #expect(FileManager.default.fileExists(atPath: file2.path) == false)

        // Pop the stash entry
        try repository.stash.pop()

        // List the stashes
        let stashes = try repository.stash.list()

        // Check the stash entries
        #expect(stashes.count == 0)  // The stash should be removed
        #expect(FileManager.default.fileExists(atPath: file2.path) == true)
        #expect(try String(contentsOf: file2) == "File 2 content\n")
    }

    @Test("Drop stash removes stash without applying")
    func stashDrop() async throws {
        let repository = mockRepository()
        try repository.mockCommit()

        // Create a file
        let file2 = try repository.mockFile()

        // Create a new stash entry
        try repository.stash.save(options: .includeUntracked)

        // Drop the stash entry
        try repository.stash.drop()

        // List the stash entries
        let stashes = try repository.stash.list()

        // Check the stash entries
        #expect(stashes.count == 0)
        #expect(FileManager.default.fileExists(atPath: file2.path) == false)
    }
}

// MARK: - Tag Extensions

extension Testing.Tag {
    @Tag static var stash: Self
}
