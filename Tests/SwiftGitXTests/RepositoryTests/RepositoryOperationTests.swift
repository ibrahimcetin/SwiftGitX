//
//  RepositoryOperationTests.swift
//
//
//  Created by İbrahim Çetin on 18.06.2024.
//

import SwiftGitX
import XCTest

final class RepositoryOperationTests: SwiftGitXTestCase {
    func testAdd() throws {
        // Create a new repository at the temporary directory
        let repository = Repository.mock(named: "test-add", in: Self.directory)

        // Create a new file in the repository
        let file = try repository.mockFile(named: "README.md")

        // Add the file to the index
        try repository.add(file: file)

        // Get status of the repository
        let status = try repository.status(file: file)

        // Check if the file is added to the index
        XCTAssertEqual(status, [.indexNew])
    }

    func testCommit() throws {
        // Create a new repository at the temporary directory
        let repository = Repository.mock(named: "test-commit", in: Self.directory)

        // Create a new file in the repository
        let file = try repository.mockFile(named: "README.md")

        // Add the file to the index
        try repository.add(file: file)

        // Commit the changes
        let commit = try repository.commit(message: "Initial commit")

        // Get the HEAD commit
        let headCommit = try XCTUnwrap(repository.HEAD.target as? Commit)

        // Check if the HEAD commit is the same as the created commit
        XCTAssertEqual(commit, headCommit)
    }

    func testEmptyCommit() throws {
        // Create a new repository at the temporary directory
        let repository = Repository.mock(named: "test-empty-commit", in: Self.directory)

        // Create initial commit
        try repository.mockCommit(message: "Initial commit")

        // Verify that committing with no changes fails by default
        XCTAssertThrowsError(try repository.commit(message: "Empty commit without option")) { error in
            // Expect a failedToCommit error
            if case RepositoryError.failedToCommit = error {
                // Expected error
            } else {
                XCTFail("Expected failedToCommit error, got \(error)")
            }
        }

        // Verify that committing with allowEmpty option succeeds
        let emptyCommit = try repository.commit(message: "Empty commit with option", options: .allowEmpty)

        // Get the HEAD commit
        let headCommit = try XCTUnwrap(repository.HEAD.target as? Commit)

        // Check if the HEAD commit is the same as the created empty commit
        XCTAssertEqual(emptyCommit, headCommit)

        // Verify the commit message
        XCTAssertEqual(emptyCommit.message, "Empty commit with option")
    }

    func testReset() throws {
        // Create a new repository at the temporary directory
        let repository = Repository.mock(named: "test-reset", in: Self.directory)

        let initialCommit = try repository.mockCommit()

        // Create a new file in the repository
        let file = try repository.mockFile(named: "ResetMe.md")

        // Add the file to the index
        try repository.add(file: file)

        // Reset the staged changes
        try repository.reset(from: initialCommit, files: [file])

        // Get the status of the file
        let status = try repository.status(file: file)

        // Check if the file is reset
        XCTAssertEqual(status, [.workingTreeNew])
    }

    func testResetSoft() throws {
        // Create a new repository at the temporary directory
        let repository = Repository.mock(named: "test-reset-soft", in: Self.directory)

        // Create mock commit
        let initialCommit = try repository.mockCommit()

        // Create a oops commit
        try repository.mockCommit(
            message: "Oops!",
            file: repository.mockFile(named: "Undefined", content: "Reset me!")
        )

        // Reset the repository to the previous commit
        try repository.reset(to: initialCommit)

        // Get the HEAD commit
        let headCommit = try XCTUnwrap(repository.HEAD.target as? Commit)

        // Check if the HEAD commit is the same as the previous commit
        XCTAssertEqual(headCommit, initialCommit)
    }

    func testRestoreWorkingTree() throws {
        // Create a new repository at the temporary directory
        let repository = Repository.mock(named: "test-restore-working-tree", in: Self.directory)

        // Create a new file
        let fileToRestore = try repository.mockFile(named: "WorkingTree.md", content: "Hello, World!")

        // Commit the file
        try repository.mockCommit(message: "Initial commit", file: fileToRestore)

        // Modify the file
        try Data("Restore me!".utf8).write(to: fileToRestore)

        // Create a new file to stage (this should not be restored)
        let fileToStage = try repository.mockFile(named: "Stage.md", content: "Stage me!")

        // Stage the file
        try repository.add(file: fileToStage)

        // Restore the file to the head commit
        try repository.restore(paths: ["WorkingTree.md", "Stage.md"])

        // Check if the file content is the same as the head commit
        let restoredFileContent = try String(contentsOf: fileToRestore)

        XCTAssertEqual(restoredFileContent, "Hello, World!")
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileToStage.path))
    }

    func testRestoreStage() throws {
        // Create a new repository at the temporary directory
        let repository = Repository.mock(named: "test-restore-stage", in: Self.directory)

        // Create a new file
        let workingTreeFile = try repository.mockFile(named: "WorkingTree.md", content: "Hello, World!")

        // Commit the file
        try repository.mockCommit(message: "Initial commit", file: workingTreeFile)

        // Modify the file (this should not be restored)
        try Data("Should not be restored!".utf8).write(to: workingTreeFile)

        // Create a new file to stage
        let stagedFile = try repository.mockFile(named: "Stage.md", content: "Stage me!")

        // Stage the file
        try repository.add(file: stagedFile)

        // Restore the staged file
        try repository.restore(.staged, paths: ["WorkingTree.md", "Stage.md"])

        // Check the status of the staged file and content
        let stagedFileStatus = try repository.status(file: stagedFile)
        XCTAssertEqual(stagedFileStatus, [.workingTreeNew])
        XCTAssertEqual(try String(contentsOf: stagedFile), "Stage me!")

        // Check the status of the working tree file and content
        let workingTreeFileStatus = try repository.status(file: workingTreeFile)
        XCTAssertEqual(workingTreeFileStatus, [.workingTreeModified])
        XCTAssertTrue(FileManager.default.fileExists(atPath: workingTreeFile.path))
        XCTAssertEqual(try String(contentsOf: workingTreeFile), "Should not be restored!")
    }

    func testRestoreWorkingTreeAndStage() throws {
        // Create a new repository at the temporary directory
        let repository = Repository.mock(named: "test-restore-working-tree-stage", in: Self.directory)

        // Create a mock commit
        try repository.mockCommit()

        // Modify the file which is created in mockCommit
        let file = try repository.mockFile(named: "README.md", content: "Restore stage area!")

        // Add the file to the index
        try repository.add(file: file)

        // Modify the file
        try Data("Restore working tree!".utf8).write(to: file)

        // Restore the working tree and stage
        try repository.restore([.workingTree, .staged], files: [file])

        // Check the status of the file and the content
        let stagedFileStatus = try repository.status(file: file)
        XCTAssertTrue(stagedFileStatus.isEmpty) // There should be no changes (all changes are restored)
        XCTAssertEqual(try String(contentsOf: file), "Welcome to SwiftGitX!\n")

        // Create a new file to delete (this should be deleted)
        let fileToDelete = try repository.mockFile(named: "DeleteMe.md", content: "Delete me from stage area!")

        // Add the file to the index
        try repository.add(file: fileToDelete)

        // Modify the file
        try Data("Delete me from working tree!".utf8).write(to: fileToDelete)

        // Restore the working tree and stage
        try repository.restore([.workingTree, .staged], files: [fileToDelete])

        // File should be deleted
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileToDelete.path))
    }

    func testRepositoryLog() async throws {
        // Create a new repository at the temporary directory
        let repository = Repository.mock(named: "test-log", in: Self.directory)

        var createdCommits = [Commit]()
        for index in 0 ..< 10 {
            // Create a commit
            let commit = try repository.mockCommit(
                message: "Commit \(index)",
                file: repository.mockFile(named: "README-\(index).md")
            )

            createdCommits.append(commit)
        }

        // Get the log of the repository
        let commitSequence = try repository.log(from: repository.HEAD, sorting: .reverse)
        let logCommits = Array(commitSequence)

        // Check if the commits are the same
        XCTAssertEqual(logCommits, createdCommits)
    }

    func testRevert() throws {
        // Create a new repository at the temporary directory
        let repository = Repository.mock(named: "test-revert", in: Self.directory)

        let file = try repository.mockFile(named: "README.md", content: "Hello, World!")

        // Create initial commit
        try repository.mockCommit(message: "Initial commit", file: file)

        // Modify the file
        try Data("Revert me!".utf8).write(to: file)

        // Create a new commit
        let commitToRevert = try repository.mockCommit(message: "Second commit", file: file)

        // Revert the commit
        try repository.revert(commitToRevert)

        // Check the status of the file
        XCTAssertEqual(try repository.status(file: file), [.indexModified])

        // Check the content of the file
        XCTAssertEqual(try String(contentsOf: file), "Hello, World!")
    }
}
