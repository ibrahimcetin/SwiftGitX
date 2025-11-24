import SwiftGitX
import XCTest

final class ConfigCollectionTests: SwiftGitXTestCase {
    func testConfigDefaultBranchName() throws {
        let repository = Repository.mock(named: "test-config-default-branch-name", in: Self.directory)

        // Set local default branch name
        try repository.config.set("feature", forKey: "init.defaultBranch")

        XCTAssertEqual(try repository.config.defaultBranchName, "feature")
    }

    func testConfigSet() throws {
        let repository = Repository.mock(named: "test-config-set", in: Self.directory)

        // Set local default branch name
        try repository.config.set("develop", forKey: "init.defaultBranch")

        // Test if the default branch name is set
        XCTAssertEqual(try repository.config.defaultBranchName, "develop")
        // Global default branch name should not be changed
        XCTAssertEqual(try Repository.config.defaultBranchName, "main")
    }

    func testConfigString() throws {
        let repository = Repository.mock(named: "test-config-string", in: Self.directory)

        // Set local user name and email
        try repository.config.set("İbrahim Çetin", forKey: "user.name")
        try repository.config.set("mail@ibrahimcetin.dev", forKey: "user.email")

        XCTAssertEqual(try repository.config.string(forKey: "user.name"), "İbrahim Çetin")
        XCTAssertEqual(try repository.config.string(forKey: "user.email"), "mail@ibrahimcetin.dev")
    }

    func testConfigGlobalString() throws {
        // Get global default branch name
        XCTAssertEqual(try Repository.config.string(forKey: "init.defaultBranch"), "main")
    }
}
