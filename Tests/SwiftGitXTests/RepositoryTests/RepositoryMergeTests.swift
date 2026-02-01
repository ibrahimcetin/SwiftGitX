import Foundation
import SwiftGitX
import Testing

@Suite("Repository - Merge", .tags(.repository, .operation, .merge))
final class RepositoryMergeTests: SwiftGitXTest {
    @Test("Merge branch into current branch")
    func mergeBranch() throws {
        let repository = mockRepository()
        try repository.mockCommit(message: "Initial commit")

        // Save current branch
        let mainBranch = try repository.branch.current

        // Create and switch to feature branch
        let initialCommit = try repository.HEAD.target as! Commit
        let featureBranch = try repository.branch.create(named: "feature", target: initialCommit)
        try repository.switch(to: featureBranch)
        try repository.mockCommit(message: "Feature commit")

        // Switch back to main and merge feature
        try repository.switch(to: mainBranch)
        try repository.merge(branch: featureBranch)

        // Verify merge commit with 2 parents
        let mergedCommit = try repository.HEAD.target as! Commit
        let parents = try mergedCommit.parents
        #expect(parents.count == 2)
    }

    @Test("Merge with divergent branches")
    func mergeDivergent() throws {
        let repository = mockRepository()
        try repository.mockCommit(message: "Initial commit")

        // Save current branch
        let mainBranch = try repository.branch.current

        // Create feature branch
        let initialCommit = try repository.HEAD.target as! Commit
        let featureBranch = try repository.branch.create(named: "feature", target: initialCommit)
        try repository.switch(to: featureBranch)
        try repository.mockCommit(message: "Feature commit")

        // Go back to main and add a different commit
        try repository.switch(to: mainBranch)
        try repository.mockCommit(message: "Main commit")

        // Merge feature into main
        try repository.merge(branch: featureBranch)

        // Verify merge commit
        let mergedCommit = try repository.HEAD.target as! Commit
        let parents = try mergedCommit.parents
        #expect(parents.count == 2)
    }
}
