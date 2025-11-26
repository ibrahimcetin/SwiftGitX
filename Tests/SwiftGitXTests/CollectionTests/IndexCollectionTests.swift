import Foundation
import Testing

@testable import SwiftGitX

@Suite("Index Collection", .tags(.index, .collection))
final class IndexCollectionTests: SwiftGitXTest {
    @Test("Add file to index using path")
    func indexAddPath() async throws {
        let repository = mockRepository()

        // Create a file in the repository
        _ = try repository.mockFile(named: "README.md", content: "Hello, World!")

        // Stage the file using the file path
        try repository.add(path: "README.md")

        // Verify that the file is staged
        let statusEntry = try #require(repository.status().first)

        #expect(statusEntry.status == [.indexNew])  // The file is staged
        #expect(statusEntry.index?.newFile.path == "README.md")
        #expect(statusEntry.workingTree == nil)  // The file is staged and not in the working tree anymore
    }

    @Test("Add file to index using file URL")
    func indexAddFile() async throws {
        let repository = mockRepository()

        // Create a file in the repository
        let file = try repository.mockFile(named: "README.md", content: "Hello, World!")

        // Stage the file using the file URL
        try repository.add(file: file)

        // Verify that the file is staged
        let statusEntry = try #require(repository.status().first)

        #expect(statusEntry.status == [.indexNew])  // The file is staged
        #expect(statusEntry.index?.newFile.path == "README.md")
        #expect(statusEntry.workingTree == nil)  // The file is staged and not in the working tree anymore
    }

    @Test("Add multiple files to index using paths")
    func indexAddPaths() async throws {
        let repository = mockRepository()

        // Create new files in the repository
        let files = try (0..<10).map { index in
            try repository.mockFile(named: "README-\(index).md", content: "Hello, World!")
        }

        // Stage the files using the file paths
        try repository.add(paths: files.map(\.lastPathComponent))

        // Verify that the files are staged
        let statusEntries = try repository.status()

        #expect(statusEntries.count == files.count)
        #expect(statusEntries.map(\.status) == Array(repeating: [.indexNew], count: files.count))
        #expect(statusEntries.map(\.index?.newFile.path) == files.map(\.lastPathComponent))
        #expect(statusEntries.map(\.workingTree) == Array(repeating: nil, count: files.count))
    }

    @Test("Add multiple files to index using file URLs")
    func indexAddFiles() async throws {
        let repository = mockRepository()

        // Create new files in the repository
        let files = try (0..<10).map { index in
            try repository.mockFile(named: "README-\(index).md", content: "Hello, World!")
        }

        // Stage the files using the file URLs
        try repository.add(files: files)

        // Verify that the files are staged
        let statusEntries = try repository.status()

        #expect(statusEntries.count == files.count)
        #expect(statusEntries.map(\.status) == Array(repeating: [.indexNew], count: files.count))
        #expect(statusEntries.map(\.index?.newFile.path) == files.map(\.lastPathComponent))
        #expect(statusEntries.map(\.workingTree) == Array(repeating: nil, count: files.count))
    }

    @Test("Remove file from index using path")
    func indexRemovePath() async throws {
        let repository = mockRepository()

        // Create a file in the repository
        let file = try repository.mockFile(named: "README.md", content: "Hello, World!")

        // Stage the file
        try repository.add(file: file)

        // Unstage the file using the file path
        try repository.remove(path: "README.md")

        // Verify that the file is not staged
        let statusEntry = try #require(repository.status().first)

        #expect(statusEntry.status == [.workingTreeNew])
        #expect(statusEntry.index == nil)  // The file is not staged
    }

    @Test("Remove file from index using file URL")
    func indexRemoveFile() async throws {
        let repository = mockRepository()

        // Create a file in the repository
        let file = try repository.mockFile(named: "README.md", content: "Hello, World!")

        // Stage the file
        try repository.add(file: file)

        // Unstage the file using the file URL
        try repository.remove(file: file)

        // Verify that the file is not staged
        let statusEntry = try #require(repository.status().first)

        #expect(statusEntry.status == [.workingTreeNew])
        #expect(statusEntry.index == nil)  // The file is not staged
    }

    @Test("Remove multiple files from index using paths")
    func indexRemovePaths() async throws {
        let repository = mockRepository()

        // Create new files in the repository
        let files = try (0..<10).map { index in
            try repository.mockFile(named: "README-\(index).md", content: "Hello, World!")
        }

        // Stage the files
        try repository.add(files: files)

        // Unstage the files using the file paths
        try repository.remove(paths: files.map(\.lastPathComponent))

        // Verify that the files are not staged
        let statusEntries = try repository.status()

        #expect(statusEntries.count == files.count)
        #expect(statusEntries.map(\.status) == Array(repeating: [.workingTreeNew], count: files.count))
        #expect(statusEntries.map(\.index) == Array(repeating: nil, count: files.count))
    }

    @Test("Remove multiple files from index using file URLs")
    func indexRemoveFiles() async throws {
        let repository = mockRepository()

        // Create new files in the repository
        let files = try (0..<10).map { index in
            try repository.mockFile(named: "README-\(index).md", content: "Hello, World!")
        }

        // Stage the files
        try repository.add(files: files)

        // Unstage the files using the file URLs
        try repository.remove(files: files)

        // Verify that the files are not staged
        let statusEntries = try repository.status()

        #expect(statusEntries.count == files.count)
        #expect(statusEntries.map(\.status) == Array(repeating: [.workingTreeNew], count: files.count))
        #expect(statusEntries.map(\.index) == Array(repeating: nil, count: files.count))
    }

    @Test("Remove all files from index")
    func indexRemoveAll() async throws {
        let repository = mockRepository()

        // Create new files in the repository
        let files = try (0..<10).map { index in
            try repository.mockFile(named: "README-\(index).md", content: "Hello, World!")
        }

        // Stage the files
        try repository.add(files: files)

        // Unstage all files
        try repository.index.removeAll()

        // Verify all files are unstaged
        let statusEntries = try repository.status()
        #expect(statusEntries.allSatisfy { $0.index == nil })
    }
}

// MARK: - Tag Extensions

extension Testing.Tag {
    @Tag static var index: Self
}
