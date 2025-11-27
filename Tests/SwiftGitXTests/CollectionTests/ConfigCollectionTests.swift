import Foundation
import SwiftGitX
import Testing

@Suite("Config Collection", .tags(.config, .collection))
final class ConfigCollectionTests: SwiftGitXTest {
    @Test("Get and set default branch name")
    func configDefaultBranchName() async throws {
        let repository = mockRepository()

        // Set local default branch name
        try repository.config.set("init.defaultBranch", to: "feature")

        #expect(try repository.config.defaultBranchName == "feature")
    }

    @Test("Set config value locally without affecting global config")
    func configSetLocal() async throws {
        let repository = mockRepository()

        // Set local default branch name
        try repository.config.set("init.defaultBranch", to: "develop")

        // Test if the default branch name is set
        #expect(try repository.config.defaultBranchName == "develop")
        // Global default branch name should not be changed
        #expect(try Repository.config.defaultBranchName == "main")
    }

    @Test("Get and set string config values")
    func configString() async throws {
        let repository = mockRepository()

        // Set local user name and email
        try repository.config.set("user.name", to: "İbrahim Çetin")
        try repository.config.set("user.email", to: "mail@ibrahimcetin.dev")

        #expect(try repository.config.string(forKey: "user.name") == "İbrahim Çetin")
        #expect(try repository.config.string(forKey: "user.email") == "mail@ibrahimcetin.dev")
    }

    @Test("Get global config value")
    func configGlobalString() async throws {
        // Get global default branch name
        #expect(try Repository.config.string(forKey: "init.defaultBranch") == "main")
    }

    @Test("Set and retrieve multiple config values")
    func configMultipleValues() async throws {
        let repository = mockRepository()

        // Set multiple configuration values
        try repository.config.set("core.autocrlf", to: "true")
        try repository.config.set("core.filemode", to: "false")
        try repository.config.set("init.defaultBranch", to: "main")

        // Verify all values are set correctly
        #expect(try repository.config.string(forKey: "core.autocrlf") == "true")
        #expect(try repository.config.string(forKey: "core.filemode") == "false")
        #expect(try repository.config.string(forKey: "init.defaultBranch") == "main")
    }

    @Test("Override existing config value")
    func configOverride() async throws {
        let repository = mockRepository()

        // Set initial value
        try repository.config.set("init.defaultBranch", to: "develop")
        #expect(try repository.config.defaultBranchName == "develop")

        // Override with new value
        try repository.config.set("init.defaultBranch", to: "main")
        #expect(try repository.config.defaultBranchName == "main")
    }
}
