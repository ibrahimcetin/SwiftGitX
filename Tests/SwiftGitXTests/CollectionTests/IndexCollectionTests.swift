import XCTest

@testable import SwiftGitX

final class IndexCollectionTests: SwiftGitXTestCase {
    func testIndexAddPath() throws {
        // Create a repository
        let repository = Repository.mock(named: "test-index-add-path", in: Self.directory)

        // Create a file in the repository
        _ = try repository.mockFile(named: "README.md", content: "Hello, World!")

        // Stage the file using the file path
        XCTAssertNoThrow(try repository.add(path: "README.md"))

        // Verify that the file is staged
        let statusEntry = try XCTUnwrap(repository.status().first)

        XCTAssertEqual(statusEntry.status, [.indexNew])  // The file is staged
        XCTAssertEqual(statusEntry.index?.newFile.path, "README.md")
        XCTAssertNil(statusEntry.workingTree)  // The file is staged and not in the working tree anymore
    }

    func testIndexAddFile() throws {
        // Create a repository
        let repository = Repository.mock(named: "test-index-add-file", in: Self.directory)

        // Create a file in the repository
        let file = try repository.mockFile(named: "README.md", content: "Hello, World!")

        // Stage the file using the file URL
        XCTAssertNoThrow(try repository.add(file: file))

        // Verify that the file is staged
        let statusEntry = try XCTUnwrap(repository.status().first)

        XCTAssertEqual(statusEntry.status, [.indexNew])  // The file is staged
        XCTAssertEqual(statusEntry.index?.newFile.path, "README.md")
        XCTAssertNil(statusEntry.workingTree)  // The file is staged and not in the working tree anymore
    }

    func testIndexAddPaths() throws {
        // Create a repository
        let repository = Repository.mock(named: "test-index-add-paths", in: Self.directory)

        // Create new files in the repository
        let files = try (0..<10).map { index in
            try repository.mockFile(named: "README-\(index).md", content: "Hello, World!")
        }

        // Stage the files using the file paths
        XCTAssertNoThrow(try repository.add(paths: files.map(\.lastPathComponent)))

        // Verify that the files are staged
        let statusEntries = try repository.status()

        XCTAssertEqual(statusEntries.count, files.count)
        XCTAssertEqual(statusEntries.map(\.status), Array(repeating: [.indexNew], count: files.count))
        XCTAssertEqual(statusEntries.map(\.index?.newFile.path), files.map(\.lastPathComponent))
        XCTAssertEqual(statusEntries.map(\.workingTree), Array(repeating: nil, count: files.count))
    }

    func testIndexAddFiles() throws {
        // Create a repository
        let repository = Repository.mock(named: "test-index-add-files", in: Self.directory)

        // Create new files in the repository
        let files = try (0..<10).map { index in
            try repository.mockFile(named: "README-\(index).md", content: "Hello, World!")
        }

        // Stage the files using the file URLs
        XCTAssertNoThrow(try repository.add(files: files))

        // Verify that the files are staged
        let statusEntries = try repository.status()

        XCTAssertEqual(statusEntries.count, files.count)
        XCTAssertEqual(statusEntries.map(\.status), Array(repeating: [.indexNew], count: files.count))
        XCTAssertEqual(statusEntries.map(\.index?.newFile.path), files.map(\.lastPathComponent))
        XCTAssertEqual(statusEntries.map(\.workingTree), Array(repeating: nil, count: files.count))
    }

    // TODO: Add test for add all

    func testIndexRemovePath() throws {
        // Create a repository
        let repository = Repository.mock(named: "test-index-remove-path", in: Self.directory)

        // Create a file in the repository
        let file = try repository.mockFile(named: "README.md", content: "Hello, World!")

        // Stage the file
        XCTAssertNoThrow(try repository.add(file: file))

        // Unstage the file using the file path
        XCTAssertNoThrow(try repository.remove(path: "README.md"))

        // Verify that the file is not staged
        let statusEntry = try XCTUnwrap(repository.status().first)

        XCTAssertEqual(statusEntry.status, [.workingTreeNew])
        XCTAssertNil(statusEntry.index)  // The file is not staged
    }

    func testIndexRemoveFile() throws {
        // Create a repository
        let repository = Repository.mock(named: "test-index-remove-file", in: Self.directory)

        // Create a file in the repository
        let file = try repository.mockFile(named: "README.md", content: "Hello, World!")

        // Stage the file
        XCTAssertNoThrow(try repository.add(file: file))

        // Unstage the file using the file URL
        XCTAssertNoThrow(try repository.remove(file: file))

        // Verify that the file is not staged
        let statusEntry = try XCTUnwrap(repository.status().first)

        XCTAssertEqual(statusEntry.status, [.workingTreeNew])
        XCTAssertNil(statusEntry.index)  // The file is not staged
    }

    func testIndexRemovePaths() throws {
        // Create a repository
        let repository = Repository.mock(named: "test-index-remove-paths", in: Self.directory)

        // Create new files in the repository
        let files = try (0..<10).map { index in
            try repository.mockFile(named: "README-\(index).md", content: "Hello, World!")
        }

        // Stage the files
        XCTAssertNoThrow(try repository.add(files: files))

        // Unstage the files using the file paths
        XCTAssertNoThrow(try repository.remove(paths: files.map(\.lastPathComponent)))

        // Verify that the files are not staged
        let statusEntries = try repository.status()

        XCTAssertEqual(statusEntries.count, files.count)
        XCTAssertEqual(statusEntries.map(\.status), Array(repeating: [.workingTreeNew], count: files.count))
        XCTAssertEqual(statusEntries.map(\.index), Array(repeating: nil, count: files.count))
    }

    func testIndexRemoveFiles() throws {
        // Create a repository
        let repository = Repository.mock(named: "test-index-remove-files", in: Self.directory)

        // Create new files in the repository
        let files = try (0..<10).map { index in
            try repository.mockFile(named: "README-\(index).md", content: "Hello, World!")
        }

        // Stage the files
        XCTAssertNoThrow(try repository.add(files: files))

        // Unstage the files using the file URLs
        XCTAssertNoThrow(try repository.remove(files: files))

        // Verify that the files are not staged
        let statusEntries = try repository.status()

        XCTAssertEqual(statusEntries.count, files.count)
        XCTAssertEqual(statusEntries.map(\.status), Array(repeating: [.workingTreeNew], count: files.count))
        XCTAssertEqual(statusEntries.map(\.index), Array(repeating: nil, count: files.count))
    }

    func testIndexRemoveAll() throws {
        // Create a repository
        let repository = Repository.mock(named: "test-index-remove-all", in: Self.directory)

        // Create new files in the repository
        let files = try (0..<10).map { index in
            try repository.mockFile(named: "README-\(index).md", content: "Hello, World!")
        }

        // Stage the files
        XCTAssertNoThrow(try repository.add(files: files))

        // Unstage all files
        XCTAssertNoThrow(try repository.index.removeAll())
    }
}
