import Foundation
import Testing

@testable import SwiftGitX

// MARK: - Add Operations

@Suite("Index Collection - Add Operations", .tags(.index, .collection))
final class IndexAddOperationsTests: SwiftGitXTest {
    @Test("Add file to index using path")
    func indexAddPath() async throws {
        let repository = mockRepository()

        // Create a file in the repository
        let file = try repository.mockFile()

        // Stage the file using the file path
        try repository.add(file: file)

        // Verify that the file is staged
        let statusEntry = try #require(repository.status().first)

        #expect(statusEntry.status == [.indexNew])  // The file is staged
        #expect(statusEntry.index?.newFile.path == "file-1.txt")
        #expect(statusEntry.workingTree == nil)  // The file is staged and not in the working tree anymore
    }

    @Test("Add file to index using file URL")
    func indexAddFile() async throws {
        let repository = mockRepository()

        // Create a file in the repository
        let file = try repository.mockFile()

        // Stage the file using the file URL
        try repository.add(file: file)

        // Verify that the file is staged
        let statusEntry = try #require(repository.status().first)

        #expect(statusEntry.status == [.indexNew])  // The file is staged
        #expect(statusEntry.index?.newFile.path == "file-1.txt")
        #expect(statusEntry.workingTree == nil)  // The file is staged and not in the working tree anymore
    }

    @Test("Add multiple files to index using paths")
    func indexAddPaths() async throws {
        let repository = mockRepository()

        // Create new files in the repository
        let files = try (0..<9).map { _ in
            try repository.mockFile()
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
        let files = try (0..<9).map { _ in
            try repository.mockFile()
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
}

// MARK: - Remove Operations

@Suite("Index Collection - Remove Operations", .tags(.index, .collection))
final class IndexRemoveOperationsTests: SwiftGitXTest {
    @Test("Remove file from index using path")
    func indexRemovePath() async throws {
        let repository = mockRepository()

        // Create a file in the repository
        let file = try repository.mockFile()

        // Stage the file
        try repository.add(file: file)

        // Unstage the file using the file path
        try repository.remove(path: "file-1.txt")

        // Verify that the file is not staged
        let statusEntry = try #require(repository.status().first)

        #expect(statusEntry.status == [.workingTreeNew])
        #expect(statusEntry.index == nil)  // The file is not staged
    }

    @Test("Remove file from index using file URL")
    func indexRemoveFile() async throws {
        let repository = mockRepository()

        // Create a file in the repository
        let file = try repository.mockFile()

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
        let files = try (0..<9).map { _ in
            try repository.mockFile()
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
        let files = try (0..<9).map { _ in
            try repository.mockFile()
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
        let files = try (0..<9).map { _ in
            try repository.mockFile()
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

// MARK: - Subdirectory Operations

@Suite("Index Collection - Subdirectories", .tags(.index, .collection))
final class IndexSubdirectoryTests: SwiftGitXTest {
    @Test("Add file in subdirectory using path")
    func indexAddSubdirectoryPath() async throws {
        let repository = mockRepository()

        // Create a subdirectory and file
        let subdirPath = try repository.workingDirectory.appending(component: "src")
        try FileManager.default.createDirectory(at: subdirPath, withIntermediateDirectories: true)

        let filePath = subdirPath.appending(component: "main.swift")
        try "print(\"Hello\")".write(to: filePath, atomically: true, encoding: .utf8)

        // Stage the file using relative path
        try repository.add(path: "src/main.swift")

        // Verify that the file is staged
        let statusEntry = try #require(repository.status().first)
        #expect(statusEntry.status == [.indexNew])
        #expect(statusEntry.index?.newFile.path == "src/main.swift")
    }

    @Test("Add file in nested subdirectories")
    func indexAddNestedSubdirectories() async throws {
        let repository = mockRepository()

        // Create nested subdirectories
        let nestedPath = try repository.workingDirectory.appending(components: "docs", "api", "v1")
        try FileManager.default.createDirectory(at: nestedPath, withIntermediateDirectories: true)

        let filePath = nestedPath.appending(component: "endpoints.md")
        try "# API Endpoints".write(to: filePath, atomically: true, encoding: .utf8)

        // Stage the file using file URL
        try repository.add(file: filePath)

        // Verify that the file is staged
        let statusEntry = try #require(repository.status().first)
        #expect(statusEntry.status == [.indexNew])
        #expect(statusEntry.index?.newFile.path == "docs/api/v1/endpoints.md")
    }

    @Test("Add multiple files in different subdirectories")
    func indexAddMultipleSubdirectories() async throws {
        let repository = mockRepository()

        // Create files in different subdirectories
        var files: [URL] = []

        for dir in ["src", "tests", "docs"] {
            let dirPath = try repository.workingDirectory.appending(component: dir)
            try FileManager.default.createDirectory(at: dirPath, withIntermediateDirectories: true)

            let filePath = dirPath.appending(component: "file.txt")
            try "Content".write(to: filePath, atomically: true, encoding: .utf8)
            files.append(filePath)
        }

        // Stage all files
        try repository.add(files: files)

        // Verify all files are staged
        let statusEntries = try repository.status()
        #expect(statusEntries.count == 3)
        #expect(statusEntries.allSatisfy { $0.status == [.indexNew] })

        let paths = statusEntries.compactMap(\.index?.newFile.path).sorted()
        #expect(paths == ["docs/file.txt", "src/file.txt", "tests/file.txt"])
    }
}

// MARK: - Modified Files Workflow

@Suite("Index Collection - Modified Files", .tags(.index, .collection))
final class IndexModifiedFilesTests: SwiftGitXTest {
    @Test("Stage file then modify it shows both staged and modified")
    func indexStageAndModify() async throws {
        let repository = mockRepository()

        // Create and stage a file
        let file = try repository.mockFile()
        try repository.add(file: file)

        // Commit to make it tracked
        try repository.commit(message: "Initial commit")

        // Modify the file
        try "Modified content".write(to: file, atomically: true, encoding: .utf8)

        // Verify file shows as modified in working tree
        let statusEntry = try #require(repository.status().first)
        #expect(statusEntry.status == [.workingTreeModified])
        #expect(statusEntry.workingTree != nil)
    }

    @Test("Restage modified file")
    func indexRestageModifiedFile() async throws {
        let repository = mockRepository()

        // Create, stage, and commit a file
        let file = try repository.mockFile()
        try repository.add(file: file)
        try repository.commit(message: "Initial commit")

        // Modify and restage the file
        try "Modified content".write(to: file, atomically: true, encoding: .utf8)
        try repository.add(file: file)

        // Verify file is staged with new content
        let statusEntry = try #require(repository.status().first)
        #expect(statusEntry.status == [.indexModified])
        #expect(statusEntry.index != nil)
        #expect(statusEntry.workingTree == nil)
    }

    @Test("Stage file, modify it, stage again")
    func indexMultipleStages() async throws {
        let repository = mockRepository()

        // Create, stage, and commit initial version
        let file = try repository.mockFile()
        try repository.add(file: file)
        try repository.commit(message: "Initial commit")

        // Modify and stage (version 2)
        try "Modified version 2".write(to: file, atomically: true, encoding: .utf8)
        try repository.add(file: file)

        // Modify again (version 3) - should show staged and modified
        try "Modified version 3".write(to: file, atomically: true, encoding: .utf8)

        let statusEntry = try #require(repository.status().first)
        #expect(statusEntry.status == [.indexModified, .workingTreeModified])
    }
}

// MARK: - Error Cases

@Suite("Index Collection - Error Cases", .tags(.index, .collection, .error))
final class IndexErrorTests: SwiftGitXTest {
    @Test("Add non-existent file throws error")
    func indexAddNonExistentFile() async throws {
        let repository = mockRepository()

        // Try to add a file that doesn't exist
        #expect(throws: SwiftGitXError.self) {
            try repository.add(path: "non-existent-file.txt")
        }
    }

    @Test("Remove file not in index succeeds as no-op")
    func indexRemoveNotStaged() async throws {
        let repository = mockRepository()

        // Create a file but don't stage it
        let file = try repository.mockFile()

        // Verify file is not staged initially
        let statusBefore = try repository.status().first
        #expect(statusBefore?.status == [.workingTreeNew])
        #expect(statusBefore?.index == nil)

        // Try to remove it from index (should succeed as no-op since it's not in the index)
        try repository.remove(path: file.lastPathComponent)

        // Verify file is still not staged (nothing changed)
        let statusAfter = try repository.status().first
        #expect(statusAfter?.status == [.workingTreeNew])
        #expect(statusAfter?.index == nil)
    }

    @Test("Add file outside repository throws error")
    func indexAddFileOutsideRepo() async throws {
        let repository = mockRepository()

        // Create a file outside the repository
        let tempFile = FileManager.default.temporaryDirectory.appending(component: "outside.txt")
        try "content".write(to: tempFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempFile) }

        // Try to add it (should fail)
        #expect(throws: SwiftGitXError.self) {
            try repository.add(file: tempFile)
        }
    }

    @Test("Add file with invalid path throws error")
    func indexAddInvalidPath() async throws {
        let repository = mockRepository()

        // Try to add with invalid/empty path
        #expect(throws: SwiftGitXError.self) {
            try repository.add(path: "")
        }
    }
}

// MARK: - Edge Cases

@Suite("Index Collection - Edge Cases", .tags(.index, .collection))
final class IndexEdgeCasesTests: SwiftGitXTest {
    @Test("Add empty array of files succeeds")
    func indexAddEmptyArray() async throws {
        let repository = mockRepository()

        // Add empty array (should succeed but do nothing)
        try repository.add(files: [])
        try repository.add(paths: [])

        // Verify index is still empty
        let statusEntries = try repository.status()
        #expect(statusEntries.isEmpty)
    }

    @Test("Remove with empty array removes all files from index")
    func indexRemoveEmptyArray() async throws {
        let repository = mockRepository()

        // Create and stage multiple files
        let file1 = try repository.mockFile()
        let file2 = try repository.mockFile()
        let file3 = try repository.mockFile()
        try repository.add(files: [file1, file2, file3])

        // Verify files are staged
        let statusBefore = try repository.status()
        #expect(statusBefore.count == 3)
        #expect(statusBefore.allSatisfy { $0.status == [.indexNew] })

        // Remove with empty array (empty pathspec matches all files)
        try repository.remove(paths: [])

        // Verify all files are unstaged (removed from index)
        let statusAfter = try repository.status()
        #expect(statusAfter.count == 3)
        #expect(statusAfter.allSatisfy { $0.status == [.workingTreeNew] })
        #expect(statusAfter.allSatisfy { $0.index == nil })
    }

    @Test("Add file with spaces in name")
    func indexAddFileWithSpaces() async throws {
        let repository = mockRepository()

        // Create file with spaces in name
        let file = try repository.mockFile()
        try repository.add(file: file)

        // Verify file is staged
        let statusEntry = try #require(repository.status().first)
        #expect(statusEntry.status == [.indexNew])
        #expect(statusEntry.index?.newFile.path == "file-1.txt")
    }

    @Test("Add file with special characters in name")
    func indexAddFileWithSpecialCharacters() async throws {
        let repository = mockRepository()

        // Create file with special characters (that are valid in filenames)
        let file = try repository.mockFile()
        try repository.add(file: file)

        // Verify file is staged
        let statusEntry = try #require(repository.status().first)
        #expect(statusEntry.status == [.indexNew])
        #expect(statusEntry.index?.newFile.path == "file-1.txt")
    }
}

// MARK: - Mixed Operations

@Suite("Index Collection - Mixed Operations", .tags(.index, .collection))
final class IndexMixedOperationsTests: SwiftGitXTest {
    @Test("Add and remove different files in one operation")
    func indexMixedAddRemove() async throws {
        let repository = mockRepository()

        // Create and stage initial files
        let file1 = try repository.mockFile()
        let file2 = try repository.mockFile()
        try repository.add(files: [file1, file2])
        try repository.commit(message: "Initial commit")

        // Create new files to add
        let file3 = try repository.mockFile()

        // Add new file and remove one old file
        try repository.add(file: file3)
        try FileManager.default.removeItem(at: file1)
        try repository.remove(file: file1)  // Stage the deletion

        // Verify mixed state
        let statusEntries = try repository.status()
        #expect(statusEntries.count == 2)

        // file1 should be staged for deletion
        let file1Status = statusEntries.first(where: { $0.index?.newFile.path == "file-1.txt" })
        #expect(file1Status?.status == [.indexDeleted])

        // file3 should be new in index
        let file3Status = statusEntries.first(where: { $0.index?.newFile.path == "file-3.txt" })
        #expect(file3Status?.status == [.indexNew])
    }

    @Test("Stage files in multiple steps and verify cumulative state")
    func indexCumulativeStaging() async throws {
        let repository = mockRepository()

        // Create files
        let file1 = try repository.mockFile()
        let file2 = try repository.mockFile()
        let file3 = try repository.mockFile()

        // Stage files one by one
        try repository.add(file: file1)
        var statusEntries = try repository.status().filter { $0.status == [.indexNew] }
        #expect(statusEntries.count == 1)

        try repository.add(file: file2)
        statusEntries = try repository.status().filter { $0.status == [.indexNew] }
        #expect(statusEntries.count == 2)

        try repository.add(file: file3)
        statusEntries = try repository.status().filter { $0.status == [.indexNew] }
        #expect(statusEntries.count == 3)

        // Verify all are staged
        #expect(statusEntries.allSatisfy { $0.status == [.indexNew] })

        let paths = statusEntries.compactMap(\.index?.newFile.path).sorted()
        let expectedPaths = [file1, file2, file3].map(\.lastPathComponent).sorted()
        #expect(paths == expectedPaths)
    }

    @Test("Partial unstaging of files")
    func indexPartialUnstaging() async throws {
        let repository = mockRepository()

        // Create and stage multiple files
        let files = try (0..<5).map { _ in
            try repository.mockFile()
        }
        try repository.add(files: files)

        // Verify all are staged
        var statusEntries = try repository.status()
        #expect(statusEntries.count == 5)

        // Unstage only 2 files
        try repository.remove(files: [files[1], files[3]])

        // Verify partial unstaging
        statusEntries = try repository.status()
        #expect(statusEntries.count == 5)

        let stagedFiles = statusEntries.filter { $0.status == [.indexNew] }
        let unstagedFiles = statusEntries.filter { $0.status == [.workingTreeNew] }

        #expect(stagedFiles.count == 3)
        #expect(unstagedFiles.count == 2)
    }
}
