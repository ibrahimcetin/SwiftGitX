import Foundation

extension URL {
    /// Returns the relative path of the URL from a base URL.
    ///
    /// - Parameter base: The base URL to calculate the relative path from.
    ///
    /// - Returns: The relative path string.
    ///
    /// - Throws: `SwiftGitXError` with `.filesystem` category if the URL is not a descendant of the base URL,
    ///   or if the URLs are identical (no relative path exists).
    func relativePath(from base: URL) throws(SwiftGitXError) -> String {
        // Standardize both URLs to handle symbolic links and relative paths
        let standardizedSelf = self.standardized
        let standardizedBase = base.standardized

        // Get path components for both URLs
        let selfComponents = standardizedSelf.pathComponents
        let baseComponents = standardizedBase.pathComponents

        // Check if self is a descendant of base
        guard selfComponents.count >= baseComponents.count else {
            throw SwiftGitXError(
                code: .invalid, category: .filesystem,
                message: "Path '\(standardizedSelf.path)' is not a descendant of base path '\(standardizedBase.path)'"
            )
        }

        // Verify that all base components match
        for (selfComponent, baseComponent) in zip(selfComponents, baseComponents) {
            guard selfComponent == baseComponent else {
                throw SwiftGitXError(
                    code: .invalid, category: .filesystem,
                    message: "Path component '\(selfComponent)' does not match base component '\(baseComponent)'"
                )
            }
        }

        // The path must have components beyond the base
        // If the count is the same, the paths are identical
        // because we check that components are the same in the loop above
        guard selfComponents.count > baseComponents.count else {
            throw SwiftGitXError(
                code: .invalid, category: .filesystem,
                message: "Path '\(standardizedSelf.path)' is the same as base path '\(standardizedBase.path)'"
            )
        }

        // Get the remaining components and join them
        let relativeComponents = selfComponents.dropFirst(baseComponents.count)
        return relativeComponents.joined(separator: "/")
    }
}
