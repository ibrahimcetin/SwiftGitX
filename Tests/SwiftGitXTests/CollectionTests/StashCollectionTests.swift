import Foundation
import SwiftGitX
import Testing

// MARK: - Save Operations

@Suite("Stash Collection - Save Operations", .tags(.stash, .collection))
final class StashSaveTests: SwiftGitXTest {
    @Test("Save staged changes to stash")
    func saveStaged() async throws {
        let repository = mockRepository()
        try repository.mockCommit()

        // Create and stage a file
        let file = try repository.mockFile()
        try repository.add(file: file)

        // Stash the changes
        try repository.stash.save()

        let stashes = try repository.stash.list()
        #expect(stashes.count == 1)
    }

    @Test("Save with custom message")
    func saveWithMessage() async throws {
        let repository = mockRepository()
        try repository.mockCommit()

        // Create and stage a file
        try repository.add(file: repository.mockFile())
        try repository.stash.save(message: "Work in progress")

        let stashes = try repository.stash.list()
        #expect(stashes.count == 1)
        #expect(stashes[0].message == "On main: Work in progress")
    }

    @Test("Save with includeUntracked option")
    func saveIncludeUntracked() async throws {
        let repository = mockRepository()
        try repository.mockCommit()

        // Create untracked file (not staged)
        let file = try repository.mockFile()

        // Stash with includeUntracked
        try repository.stash.save(options: .includeUntracked)

        // File should be removed from working directory
        #expect(FileManager.default.fileExists(atPath: file.path) == false)
        #expect(try repository.stash.list().count == 1)
    }

    @Test("Save multiple stashes")
    func saveMultiple() async throws {
        let repository = mockRepository()
        try repository.mockCommit()

        // Create multiple stashes
        for i in 0..<3 {
            _ = try repository.mockFile()
            try repository.stash.save(message: "Stash #\(i)", options: .includeUntracked)
        }

        let stashes = try repository.stash.list()
        #expect(stashes.count == 3)

        // Verify order (most recent first, LIFO)
        #expect(stashes[0].message == "On main: Stash #2")
        #expect(stashes[1].message == "On main: Stash #1")
        #expect(stashes[2].message == "On main: Stash #0")
    }

    @Test("Save with nothing to stash throws error", .tags(.error))
    func saveNothingThrows() async throws {
        let repository = mockRepository()
        try repository.mockCommit()

        let error = #expect(throws: SwiftGitXError.self) {
            try repository.stash.save()
        }

        #expect(error?.code == .notFound)
        #expect(error?.category == .stash)
        #expect(error?.message == "cannot stash changes - there is nothing to stash.")
    }
}

// MARK: - List & Iterator Operations

@Suite("Stash Collection - List & Iterator", .tags(.stash, .collection))
final class StashListTests: SwiftGitXTest {
    @Test("List returns empty array when no stashes exist")
    func listEmpty() async throws {
        let repository = mockRepository()
        try repository.mockCommit()

        let stashes = try repository.stash.list()
        #expect(stashes.isEmpty)
    }

    @Test("List returns all stash entries")
    func listAll() async throws {
        let repository = mockRepository()
        try repository.mockCommit()

        // Create stashes
        for i in 0..<3 {
            try repository.add(file: repository.mockFile())
            try repository.stash.save(message: "Stash #\(i)")
        }

        let stashes = try repository.stash.list()
        #expect(stashes.count == 3)
    }

    @Test("Iterate over stash entries with correct index")
    func iterateWithIndex() async throws {
        let repository = mockRepository()
        try repository.mockCommit()

        // Create stashes
        for i in 0..<5 {
            _ = try repository.mockFile()
            try repository.stash.save(message: "Stash #\(i)", options: .includeUntracked)
        }

        // Iterate and verify indices
        for (index, entry) in repository.stash.enumerated() {
            #expect(entry.index == index)
            // Most recent is index 0 (Stash 4), oldest is index 4 (Stash 0)
            #expect(entry.message == "On main: Stash #\(4 - index)")
        }
    }
}

// MARK: - Apply Operations

@Suite("Stash Collection - Apply Operations", .tags(.stash, .collection))
final class StashApplyTests: SwiftGitXTest {
    @Test("Apply restores changes and keeps stash entry")
    func applyKeepsEntry() async throws {
        let repository = mockRepository()
        try repository.mockCommit()

        // Create and stash a file
        let file = try repository.mockFile()
        try repository.stash.save(options: .includeUntracked)

        #expect(FileManager.default.fileExists(atPath: file.path) == false)

        // Apply the stash
        try repository.stash.apply()

        // File restored, stash still exists
        #expect(FileManager.default.fileExists(atPath: file.path) == true)
        #expect(try repository.stash.list().count == 1)
    }

    @Test("Apply specific stash entry by reference")
    func applySpecific() async throws {
        let repository = mockRepository()
        try repository.mockCommit()

        // Create two stashes with different files
        let file1 = try repository.mockFile(name: "first.txt")
        try repository.stash.save(message: "First", options: .includeUntracked)

        let file2 = try repository.mockFile(name: "second.txt")
        try repository.stash.save(message: "Second", options: .includeUntracked)

        // Both files gone
        #expect(FileManager.default.fileExists(atPath: file1.path) == false)
        #expect(FileManager.default.fileExists(atPath: file2.path) == false)

        // Apply the older stash (index 1)
        let stashes = try repository.stash.list()
        try repository.stash.apply(stashes[1])

        // Only first file restored
        #expect(FileManager.default.fileExists(atPath: file1.path) == true)
        #expect(FileManager.default.fileExists(atPath: file2.path) == false)

        // Both stashes still exist
        #expect(try repository.stash.list().count == 2)
    }

    @Test("Apply on empty stash throws error", .tags(.error))
    func applyEmptyThrows() async throws {
        let repository = mockRepository()
        try repository.mockCommit()

        #expect(throws: SwiftGitXError.self) {
            try repository.stash.apply()
        }
    }
}

// MARK: - Pop Operations

@Suite("Stash Collection - Pop Operations", .tags(.stash, .collection))
final class StashPopTests: SwiftGitXTest {
    @Test("Pop restores changes and removes stash entry")
    func popRemovesEntry() async throws {
        let repository = mockRepository()
        try repository.mockCommit()

        // Create and stash a file
        let file = try repository.mockFile()
        try repository.stash.save(options: .includeUntracked)

        #expect(FileManager.default.fileExists(atPath: file.path) == false)
        #expect(try repository.stash.list().count == 1)

        // Pop the stash
        try repository.stash.pop()

        // File restored, stash removed
        #expect(FileManager.default.fileExists(atPath: file.path) == true)
        #expect(try repository.stash.list().count == 0)
    }

    @Test("Pop specific stash entry by reference")
    func popSpecific() async throws {
        let repository = mockRepository()
        try repository.mockCommit()

        // Create two stashes
        let file1 = try repository.mockFile(name: "first.txt")
        try repository.stash.save(message: "First", options: .includeUntracked)

        _ = try repository.mockFile(name: "second.txt")
        try repository.stash.save(message: "Second", options: .includeUntracked)

        // Pop the older stash (index 1)
        let stashes = try repository.stash.list()
        try repository.stash.pop(stashes[1])

        // First file restored, only second stash remains
        #expect(FileManager.default.fileExists(atPath: file1.path) == true)
        #expect(try repository.stash.list().count == 1)
        #expect(try repository.stash.list()[0].message == "On main: Second")
    }

    @Test("Pop on empty stash throws error", .tags(.error))
    func popEmptyThrows() async throws {
        let repository = mockRepository()
        try repository.mockCommit()

        #expect(throws: SwiftGitXError.self) {
            try repository.stash.pop()
        }
    }
}

// MARK: - Drop Operations

@Suite("Stash Collection - Drop Operations", .tags(.stash, .collection))
final class StashDropTests: SwiftGitXTest {
    @Test("Drop removes stash without applying changes")
    func dropDiscards() async throws {
        let repository = mockRepository()
        try repository.mockCommit()

        // Create and stash a file
        let file = try repository.mockFile()
        try repository.stash.save(options: .includeUntracked)

        // Drop the stash
        try repository.stash.drop()

        // File still gone, stash removed
        #expect(FileManager.default.fileExists(atPath: file.path) == false)
        #expect(try repository.stash.list().count == 0)
    }

    @Test("Drop specific stash entry by reference")
    func dropSpecific() async throws {
        let repository = mockRepository()
        try repository.mockCommit()

        // Create two stashes
        _ = try repository.mockFile()
        try repository.stash.save(message: "First", options: .includeUntracked)

        _ = try repository.mockFile()
        try repository.stash.save(message: "Second", options: .includeUntracked)

        #expect(try repository.stash.list().count == 2)

        // Drop the newer stash (index 0)
        let stashes = try repository.stash.list()
        try repository.stash.drop(stashes[0])

        // Only older stash remains
        let remaining = try repository.stash.list()
        #expect(remaining.count == 1)
        #expect(remaining[0].message == "On main: First")
    }

    @Test("Drop on empty stash throws error", .tags(.error))
    func dropEmptyThrows() async throws {
        let repository = mockRepository()
        try repository.mockCommit()

        #expect(throws: SwiftGitXError.self) {
            try repository.stash.drop()
        }
    }
}
