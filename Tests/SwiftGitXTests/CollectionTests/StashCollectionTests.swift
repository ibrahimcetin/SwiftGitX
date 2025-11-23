import SwiftGitX
import XCTest

final class StashCollectionTests: SwiftGitXTestCase {
    func testStashSave() throws {
        // Create a new repository at the temporary directory
        let repository = Repository.mock(named: "test-stash-save", in: Self.directory)

        // Create mock commit
        try repository.mockCommit()

        // Create a file
        let fileURL = try URL(fileURLWithPath: "test.txt", relativeTo: repository.workingDirectory)
        FileManager.default.createFile(atPath: fileURL.path, contents: Data("Stash me!".utf8))

        // Stage the file
        try repository.add(path: fileURL.lastPathComponent)

        // Create a new stash entry
        try repository.stash.save()

        // List the stash entries
        let stashes = try repository.stash.list()

        // Check the stash entries
        XCTAssertEqual(stashes.count, 1)
    }

    func testStashSaveFailure() throws {
        // Create a new repository at the temporary directory
        let repository = Repository.mock(named: "test-stash-save-failure", in: Self.directory)

        // Create mock commit
        try repository.mockCommit()

        // Create a new stash entry
        XCTAssertThrowsError(try repository.stash.save()) { error in
            XCTAssertEqual(error as? StashCollectionError, .noLocalChangesToSave)
        }
    }

    func testStashList() throws {
        // Create a new repository at the temporary directory
        let repository = Repository.mock(named: "test-stash-list", in: Self.directory)

        // Create mock commit
        try repository.mockCommit()

        for index in 0..<5 {
            // Create a file
            _ = try repository.mockFile(named: "test\(index).txt", content: "Stash me!")

            // Create a new stash
            try repository.stash.save(message: "Stashed \(index)!", options: .includeUntracked)
        }

        // List the stash entries
        let stashes = try repository.stash.list()

        // Check the stash entries
        XCTAssertEqual(stashes.count, 5)
    }

    func testStashIterator() throws {
        // Create a new repository at the temporary directory
        let repository = Repository.mock(named: "test-stash-iterator", in: Self.directory)

        // Create mock commit
        try repository.mockCommit()

        for index in 0..<5 {
            // Create a file
            _ = try repository.mockFile(named: "test-\(index).txt", content: "Stash me!")

            // Create a new stash
            try repository.stash.save(message: "Stashed \(index)!", options: .includeUntracked)
        }

        // Iterate over the stash entries
        for (index, entry) in repository.stash.enumerated() {
            XCTAssertEqual(entry.index, index)
            XCTAssertEqual(entry.message, "On main: Stashed \(4 - index)!")
        }
    }

    func testStashApply() throws {
        // Create a new repository at the temporary directory
        let repository = Repository.mock(named: "test-stash-apply", in: Self.directory)

        // Create mock commit
        try repository.mockCommit()

        // Create a file
        let fileURL = try URL(fileURLWithPath: "test.txt", relativeTo: repository.workingDirectory)
        FileManager.default.createFile(atPath: fileURL.path, contents: Data("Stash me!".utf8))

        // Create a new stash entry
        try repository.stash.save(options: .includeUntracked)

        XCTAssertEqual(try repository.stash.list().count, 1)
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))

        // Apply the stash entry
        try repository.stash.apply()

        // List the stashes
        let stashes = try repository.stash.list()

        // Check the stash entries
        XCTAssertEqual(stashes.count, 1)  // The stash should still exist
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        XCTAssertEqual(try String(contentsOf: fileURL), "Stash me!")
    }

    func testStashPop() throws {
        // Create a new repository at the temporary directory
        let repository = Repository.mock(named: "test-stash-pop", in: Self.directory)

        // Create mock commit
        try repository.mockCommit()

        // Create a file
        let fileURL = try URL(fileURLWithPath: "test.txt", relativeTo: repository.workingDirectory)
        FileManager.default.createFile(atPath: fileURL.path, contents: Data("Stash me!".utf8))

        // Create a new stash entry
        try repository.stash.save(options: .includeUntracked)

        XCTAssertEqual(try repository.stash.list().count, 1)
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))

        // Apply the stash entry
        try repository.stash.pop()

        // List the stashes
        let stashes = try repository.stash.list()

        // Check the stash entries
        XCTAssertEqual(stashes.count, 0)  // The stash should be removed
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        XCTAssertEqual(try String(contentsOf: fileURL), "Stash me!")
    }

    func testStashDrop() throws {
        // Create a new repository at the temporary directory
        let repository = Repository.mock(named: "test-stash-drop", in: Self.directory)

        // Create mock commit
        try repository.mockCommit()

        // Create a file
        let fileURL = try URL(fileURLWithPath: "test.txt", relativeTo: repository.workingDirectory)
        FileManager.default.createFile(atPath: fileURL.path, contents: Data("Stash me!".utf8))

        // Create a new stash entry
        try repository.stash.save(options: .includeUntracked)

        // Drop the stash entry
        try repository.stash.drop()

        // List the stash entries
        let stashes = try repository.stash.list()

        // Check the stash entries
        XCTAssertEqual(stashes.count, 0)
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
    }
}
