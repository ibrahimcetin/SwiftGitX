//
//  Repository+patch.swift
//  SwiftGitX
//
//  Created by İbrahim Çetin on 23.11.2025.
//

import Foundation
import libgit2

extension Repository {
    /// Creates a patch from the difference between two blobs.
    ///
    /// - Parameters:
    ///   - oldBlob: Blob for old side of patch, or `nil` for empty blob.
    ///   - newBlob: Blob for new side of patch, or `nil` for empty blob.
    ///
    /// - Returns: The created patch.
    ///
    /// If both blobs are `nil`, the patch will be empty.
    ///
    /// If you want to create a patch from ``StatusEntry``, using ``patch(from:)`` method
    /// for ``StatusEntry/workingTree`` and ``StatusEntry/index`` is recommended.
    /// But if you will use this method, be sure the file is staged because workingTree files'
    /// ``Diff/Delta/newFile`` side's ``Diff/File/id`` property does not have a valid blob id.
    /// So, you have to use ``patch(from:to:)-957bd`` method to create patch for the workingTree file.
    /// If the file's status is ``StatusEntry/Status-swift.enum/workingTreeNew`` (aka `untracked`)
    /// you should use ``patch(from:to:)-957bd`` method with `nil` oldBlob.
    public func patch(from oldBlob: Blob?, to newBlob: Blob?) throws -> Patch {
        let oldBlobPointer: OpaquePointer?
        let newBlobPointer: OpaquePointer?

        // Get the blob pointers if not nil
        oldBlobPointer =
            if let oldBlob {
                try ObjectFactory.lookupObjectPointer(
                    oid: oldBlob.id.raw,
                    type: GIT_OBJECT_BLOB,
                    repositoryPointer: pointer
                )
            } else { nil }
        defer { git_object_free(oldBlobPointer) }

        newBlobPointer =
            if let newBlob {
                try ObjectFactory.lookupObjectPointer(
                    oid: newBlob.id.raw,
                    type: GIT_OBJECT_BLOB,
                    repositoryPointer: pointer
                )
            } else { nil }
        defer { git_object_free(newBlobPointer) }

        // Create the patch object
        var patchPointer: OpaquePointer?
        defer { git_patch_free(patchPointer) }

        let patchStatus = git_patch_from_blobs(
            &patchPointer, oldBlobPointer, nil, newBlobPointer, nil, nil)

        guard let patchPointer, patchStatus == GIT_OK.rawValue else {
            let errorMessage = String(cString: git_error_last().pointee.message)
            throw RepositoryError.failedToCreatePatch(errorMessage)
        }

        return Patch(pointer: patchPointer)
    }

    /// Creates a patch from the difference between a blob and a file.
    ///
    /// - Parameters:
    ///   - blob: Blob for old side of patch, or `nil` for empty blob.
    ///   - file: URL of the file for new side of patch.
    ///
    /// - Returns: The created patch.
    public func patch(from blob: Blob?, to file: URL) throws -> Patch {
        // Get the blob pointer if not nil
        let blobPointer: OpaquePointer?

        blobPointer =
            if let blob {
                try ObjectFactory.lookupObjectPointer(
                    oid: blob.id.raw,
                    type: GIT_OBJECT_BLOB,
                    repositoryPointer: pointer
                )
            } else { nil }
        defer { git_object_free(blobPointer) }

        // Get the new file content
        let fileContent = try Data(contentsOf: file) as NSData

        // Create the patch object
        var patchPointer: OpaquePointer?
        defer { git_patch_free(patchPointer) }

        let patchStatus = git_patch_from_blob_and_buffer(
            &patchPointer,
            blobPointer,
            nil,
            fileContent.bytes,
            fileContent.count,
            nil,
            nil
        )

        guard let patchPointer, patchStatus == GIT_OK.rawValue else {
            let errorMessage = String(cString: git_error_last().pointee.message)
            throw RepositoryError.failedToCreatePatch(errorMessage)
        }

        return Patch(pointer: patchPointer)
    }

    /// Creates a patch from given diff delta.
    ///
    /// - Parameter delta: The diff delta to create the patch from.
    ///
    /// - Returns: The created patch.
    ///
    /// This method does not support all diff delta types.
    /// It only supports ``Diff/DeltaType/untracked``, ``Diff/DeltaType/added``, and ``Diff/DeltaType/modified`` types,
    /// for now.
    public func patch(from delta: Diff.Delta) throws -> Patch? {
        // TODO: Complete the all cases
        switch delta.type {
        case .untracked:
            let newFileURL = try workingDirectory.appendingPathComponent(delta.newFile.path)
            // Create a patch from an empty blob to the file content
            return try patch(from: nil, to: newFileURL)
        case .added:
            let oldBlobID = delta.oldFile.id
            let oldBlob: Blob = try show(id: oldBlobID)

            let newBlobID = delta.newFile.id
            let newBlob: Blob = try show(id: newBlobID)

            // Create a patch from the old blob to the new blob
            return try patch(from: oldBlob, to: newBlob)
        case .modified, .renamed:
            let oldBlobID = delta.oldFile.id
            let oldBlob: Blob = try show(id: oldBlobID)

            let newFileURL = try workingDirectory.appendingPathComponent(delta.newFile.path)

            // Create a patch from the old blob to the file content
            return try patch(from: oldBlob, to: newFileURL)
        default:
            return nil
        }
    }
}
