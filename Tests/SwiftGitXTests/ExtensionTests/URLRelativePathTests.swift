//
//  URLRelativePathTests.swift
//  SwiftGitX
//
//  Created on 24.11.2025.
//

import Foundation
import Testing

@testable import SwiftGitX

/// Tests for the URL relativePath(from:) extension method.
@Suite("URL Relative Path Extension")
struct URLRelativePathTests {

    // MARK: - Happy Path Tests

    @Test("Returns correct relative path for direct child")
    func directChild() throws {
        let base = URL(fileURLWithPath: "/Users/developer/projects")
        let child = URL(fileURLWithPath: "/Users/developer/projects/SwiftGitX")

        let relativePath = try child.relativePath(from: base)
        #expect(relativePath == "SwiftGitX")
    }

    @Test("Returns correct relative path for nested child")
    func nestedChild() throws {
        let base = URL(fileURLWithPath: "/Users/developer")
        let child = URL(fileURLWithPath: "/Users/developer/projects/SwiftGitX")

        let relativePath = try child.relativePath(from: base)
        #expect(relativePath == "projects/SwiftGitX")
    }

    @Test("Returns correct relative path for deeply nested child")
    func deeplyNestedChild() throws {
        let base = URL(fileURLWithPath: "/Users")
        let child = URL(fileURLWithPath: "/Users/developer/projects/SwiftGitX/Sources/Models")

        let relativePath = try child.relativePath(from: base)
        #expect(relativePath == "developer/projects/SwiftGitX/Sources/Models")
    }

    @Test("Handles trailing slashes correctly")
    func trailingSlashes() throws {
        let base = URL(fileURLWithPath: "/Users/developer/projects/")
        let child = URL(fileURLWithPath: "/Users/developer/projects/SwiftGitX")

        let relativePath = try child.relativePath(from: base)
        #expect(relativePath == "SwiftGitX")
    }

    @Test("Handles paths with spaces")
    func pathsWithSpaces() throws {
        let base = URL(fileURLWithPath: "/Users/My Developer/My Projects")
        let child = URL(fileURLWithPath: "/Users/My Developer/My Projects/Swift GitX")

        let relativePath = try child.relativePath(from: base)
        #expect(relativePath == "Swift GitX")
    }

    @Test("Handles paths with special characters")
    func pathsWithSpecialCharacters() throws {
        let base = URL(fileURLWithPath: "/Users/developer/projects-2025")
        let child = URL(fileURLWithPath: "/Users/developer/projects-2025/app_v1.0")

        let relativePath = try child.relativePath(from: base)
        #expect(relativePath == "app_v1.0")
    }

    // MARK: - Error Cases

    @Test("Throws error when path is not a descendant (shorter path)")
    func notDescendantShorterPath() throws {
        let base = URL(fileURLWithPath: "/Users/developer/projects/SwiftGitX")
        let notChild = URL(fileURLWithPath: "/Users/developer")

        let error = #expect(throws: SwiftGitXError.self) {
            try notChild.relativePath(from: base)
        }

        #expect(error?.code == .invalid)
        #expect(error?.category == .filesystem)
        #expect(error?.message.contains("not a descendant") == true)
    }

    @Test("Throws error when path components don't match")
    func pathComponentsDontMatch() throws {
        let base = URL(fileURLWithPath: "/Users/developer/projects")
        let differentPath = URL(fileURLWithPath: "/Users/developer/documents/file.txt")

        let error = #expect(throws: SwiftGitXError.self) {
            try differentPath.relativePath(from: base)
        }

        #expect(error?.code == .invalid)
        #expect(error?.category == .filesystem)
        #expect(error?.message.contains("does not match") == true)
    }

    @Test("Throws error when paths are identical")
    func identicalPaths() throws {
        let path1 = URL(fileURLWithPath: "/Users/developer/projects")
        let path2 = URL(fileURLWithPath: "/Users/developer/projects")

        let error = #expect(throws: SwiftGitXError.self) {
            try path1.relativePath(from: path2)
        }

        #expect(error?.code == .invalid)
        #expect(error?.category == .filesystem)
        #expect(error?.message.contains("is the same as") == true)
    }

    @Test("Throws error when paths are identical with trailing slash difference")
    func identicalPathsWithTrailingSlash() throws {
        let path1 = URL(fileURLWithPath: "/Users/developer/projects")
        let path2 = URL(fileURLWithPath: "/Users/developer/projects/")

        let error = #expect(throws: SwiftGitXError.self) {
            try path1.relativePath(from: path2)
        }

        #expect(error?.code == .invalid)
        #expect(error?.category == .filesystem)
        #expect(error?.message.contains("is the same as") == true)
    }

    // MARK: - Edge Cases

    @Test("Handles root path as base")
    func rootPathAsBase() throws {
        let base = URL(fileURLWithPath: "/")
        let child = URL(fileURLWithPath: "/Users/developer")

        let relativePath = try child.relativePath(from: base)
        #expect(relativePath == "Users/developer")
    }

    @Test("Handles single-level relative path")
    func singleLevelRelativePath() throws {
        let base = URL(fileURLWithPath: "/var")
        let child = URL(fileURLWithPath: "/var/log")

        let relativePath = try child.relativePath(from: base)
        #expect(relativePath == "log")
    }

    @Test("Handles paths with dots in component names")
    func pathsWithDotsInNames() throws {
        let base = URL(fileURLWithPath: "/Users/developer")
        let child = URL(fileURLWithPath: "/Users/developer/project.v1.0/file.txt")

        let relativePath = try child.relativePath(from: base)
        #expect(relativePath == "project.v1.0/file.txt")
    }

    // MARK: - Standardization Tests

    @Test("Standardizes paths before comparison")
    func standardizesPathsBeforeComparison() throws {
        // Create URLs with relative path components
        let base = URL(fileURLWithPath: "/Users/developer/projects")
        // Use a path with .. which should be standardized
        let child = URL(fileURLWithPath: "/Users/developer/projects/SwiftGitX/../SwiftGitX/Sources")

        let relativePath = try child.relativePath(from: base)
        #expect(relativePath == "SwiftGitX/Sources")
    }

    @Test("Handles non-standardized base path")
    func nonStandardizedBasePath() throws {
        let base = URL(fileURLWithPath: "/Users/developer/../developer/projects")
        let child = URL(fileURLWithPath: "/Users/developer/projects/SwiftGitX")

        let relativePath = try child.relativePath(from: base)
        #expect(relativePath == "SwiftGitX")
    }

    // MARK: - Case Sensitivity Tests (macOS specific)

    #if os(macOS)
        @Test("Handles case differences on macOS (case-insensitive filesystem)")
        func caseDifferencesOnMacOS() throws {
            // On macOS, the default APFS filesystem is case-insensitive
            // This test might behave differently depending on the filesystem
            let base = URL(fileURLWithPath: "/Users/developer/projects")
            let child = URL(fileURLWithPath: "/Users/Developer/Projects/SwiftGitX")

            // Note: This test might fail on case-sensitive filesystems
            // The behavior depends on the underlying filesystem
            do {
                let relativePath = try child.relativePath(from: base)
                // If successful, verify the result
                #expect(relativePath == "SwiftGitX")
            } catch let error {
                // On case-sensitive filesystems, this should throw an error
                #expect(error.code == .invalid)
                #expect(error.category == .filesystem)
            }
        }
    #endif

    // MARK: - Multiple Components Tests

    @Test("Returns multiple path components correctly")
    func multiplePathComponents() throws {
        let base = URL(fileURLWithPath: "/a")
        let child = URL(fileURLWithPath: "/a/b/c/d/e/f")

        let relativePath = try child.relativePath(from: base)
        #expect(relativePath == "b/c/d/e/f")
    }

    @Test("Handles complex real-world paths")
    func complexRealWorldPaths() throws {
        let base = URL(fileURLWithPath: "/Users/ibrahim/Developer/")
        let child = URL(fileURLWithPath: "/Users/ibrahim/Developer/SwiftGitX/Sources/SwiftGitX/Helpers/Extensions")

        let relativePath = try child.relativePath(from: base)
        #expect(relativePath == "SwiftGitX/Sources/SwiftGitX/Helpers/Extensions")
    }
}
