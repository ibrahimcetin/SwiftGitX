import Foundation
import libgit2

extension [String] {
    /// Converts the array of strings to a `git_strarray` instance.
    ///
    /// - Returns: A `git_strarray` instance.
    ///
    /// - Important: The returned `git_strarray` instance must be freed using `git_strarray_free`.
    var gitStrArray: git_strarray {
        // Create an array of C strings
        var cStrings = self.map { strdup($0) }

        // Create a pointer to the C strings
        let pointer = UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>.allocate(capacity: cStrings.count)
        pointer.initialize(from: &cStrings, count: cStrings.count)

        // Create a git_strarray instance
        return git_strarray(strings: pointer, count: cStrings.count)
    }

    /// Executes a closure with a `git_strarray` instance created from the array of strings.
    ///
    /// - Parameter body: The closure to execute.
    ///
    /// - Returns: The result of the closure.
    ///
    /// - Throws: Any error thrown by the closure.
    ///
    /// - Note: The `git_strarray` instance is freed after the closure is executed. You shouldn't use it outside the
    /// closure.
    func withGitStrArray<T>(_ body: (git_strarray) throws(SwiftGitXError) -> T) throws(SwiftGitXError) -> T {
        var strArray = gitStrArray
        defer { git_strarray_free(&strArray) }

        return try body(strArray)
    }
}
