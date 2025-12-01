import Foundation
import Testing
import libgit2

@testable import SwiftGitX

// MARK: - Initialization Tests

@Suite("Signature - Initialization", .tags(.signature, .model))
final class SignatureInitTests: SwiftGitXTest {
    @Test("Initialize with all parameters")
    func initWithAllParameters() async throws {
        let date = Date.now
        let timezone = TimeZone(identifier: "Europe/Istanbul")!

        let signature = Signature(
            name: "John Doe",
            email: "john@example.com",
            date: date,
            timezone: timezone
        )

        #expect(signature.name == "John Doe")
        #expect(signature.email == "john@example.com")
        #expect(signature.date == date)
        #expect(signature.timezone == timezone)
    }

    @Test("Initialize with default date and timezone")
    func initWithDefaults() async throws {
        let before = Date.now

        let signature = Signature(
            name: "Jane Doe",
            email: "jane@example.com"
        )

        let after = Date.now

        #expect(signature.name == "Jane Doe")
        #expect(signature.email == "jane@example.com")

        // Date should be between before and after
        #expect(signature.date >= before)
        #expect(signature.date <= after)

        // Timezone should be current
        #expect(signature.timezone == TimeZone.current)
    }

    @Test("Initialize with specific date")
    func initWithSpecificDate() async throws {
        let specificDate = Date(timeIntervalSince1970: 1_700_000_000)

        let signature = Signature(
            name: "Test User",
            email: "test@example.com",
            date: specificDate
        )

        #expect(signature.date == specificDate)
        #expect(signature.timezone == TimeZone.current)
    }

    @Test("Initialize with specific timezone")
    func initWithSpecificTimezone() async throws {
        let utc = TimeZone(identifier: "UTC")!

        let signature = Signature(
            name: "UTC User",
            email: "utc@example.com",
            timezone: utc
        )

        #expect(signature.timezone == utc)
    }
}

// MARK: - Equality Tests

@Suite("Signature - Equality & Hashing", .tags(.signature, .model))
final class SignatureEqualityTests: SwiftGitXTest {
    @Test("Equal signatures are equal")
    func equalSignatures() async throws {
        let date = Date.now
        let timezone = TimeZone.current

        let signature1 = Signature(name: "John", email: "john@example.com", date: date, timezone: timezone)
        let signature2 = Signature(name: "John", email: "john@example.com", date: date, timezone: timezone)

        #expect(signature1 == signature2)
    }

    @Test("Different names are not equal")
    func differentNames() async throws {
        let date = Date.now

        let signature1 = Signature(name: "John", email: "john@example.com", date: date)
        let signature2 = Signature(name: "Jane", email: "john@example.com", date: date)

        #expect(signature1 != signature2)
    }

    @Test("Different emails are not equal")
    func differentEmails() async throws {
        let date = Date.now

        let signature1 = Signature(name: "John", email: "john@example.com", date: date)
        let signature2 = Signature(name: "John", email: "jane@example.com", date: date)

        #expect(signature1 != signature2)
    }

    @Test("Different dates are not equal")
    func differentDates() async throws {
        let signature1 = Signature(name: "John", email: "john@example.com", date: Date.now)
        let signature2 = Signature(name: "John", email: "john@example.com", date: Date.now.addingTimeInterval(1))

        #expect(signature1 != signature2)
    }

    @Test("Equal signatures have same hash")
    func hashEquality() async throws {
        let date = Date.now
        let timezone = TimeZone.current

        let signature1 = Signature(name: "John", email: "john@example.com", date: date, timezone: timezone)
        let signature2 = Signature(name: "John", email: "john@example.com", date: date, timezone: timezone)

        #expect(signature1.hashValue == signature2.hashValue)
    }

    @Test("Signatures can be used in Set")
    func usableInSet() async throws {
        let date = Date.now

        let signature1 = Signature(name: "John", email: "john@example.com", date: date)
        let signature2 = Signature(name: "John", email: "john@example.com", date: date)
        let signature3 = Signature(name: "Jane", email: "jane@example.com", date: date)

        var set: Set<Signature> = []
        set.insert(signature1)
        set.insert(signature2)
        set.insert(signature3)

        // signature1 and signature2 are equal, so set should have 2 elements
        #expect(set.count == 2)
    }
}

// MARK: - Default Signature Tests

@Suite("Signature - Default in Repository", .tags(.signature, .model))
final class SignatureDefaultTests: SwiftGitXTest {
    @Test("Get default signature from repository")
    func defaultSignature() async throws {
        let repository = mockRepository()

        // Set git config for user
        try repository.config.set("user.name", to: "Test User")
        try repository.config.set("user.email", to: "test@example.com")

        // Get default signature
        let signature = try Signature.default(in: repository)

        #expect(signature.name == "Test User")
        #expect(signature.email == "test@example.com")
    }

    @Test("Default signature uses current date")
    func defaultSignatureDate() async throws {
        let repository = mockRepository()

        try repository.config.set("user.name", to: "Test User")
        try repository.config.set("user.email", to: "test@example.com")

        // Truncate to seconds since git_signature stores time as integer seconds
        let before = floor(Date.now.timeIntervalSince1970)
        let signature = try Signature.default(in: repository)
        let after = ceil(Date.now.timeIntervalSince1970)

        #expect(signature.date.timeIntervalSince1970 >= before)
        #expect(signature.date.timeIntervalSince1970 <= after)
    }
}

// MARK: - Raw Conversion Tests

@Suite("Signature - Raw Conversion", .tags(.signature, .model))
final class SignatureRawTests: SwiftGitXTest {
    override init() throws {
        try super.init()
        try SwiftGitXRuntime.initialize()
    }

    deinit { _ = try? SwiftGitXRuntime.shutdown() }

    @Test("Convert to raw preserves name and email")
    func rawPreservesNameAndEmail() async throws {
        let signature = Signature(
            name: "Test User",
            email: "test@example.com"
        )

        let pointer = try ObjectFactory.makeSignaturePointer(signature: signature)
        defer { git_signature_free(pointer) }

        let raw = pointer.pointee

        #expect(String(cString: raw.name) == "Test User")
        #expect(String(cString: raw.email) == "test@example.com")
    }

    @Test("Convert to raw preserves date")
    func rawPreservesDate() async throws {
        let specificDate = Date(timeIntervalSince1970: 1_700_000_000)

        let signature = Signature(
            name: "Test User",
            email: "test@example.com",
            date: specificDate
        )

        let pointer = try ObjectFactory.makeSignaturePointer(signature: signature)
        defer { git_signature_free(pointer) }

        let raw = pointer.pointee

        #expect(raw.when.time == 1_700_000_000)
    }

    @Test("Convert to raw preserves timezone offset")
    func rawPreservesTimezone() async throws {
        // UTC+3 timezone (180 minutes offset)
        let timezone = TimeZone(secondsFromGMT: 3 * 60 * 60)!

        let signature = Signature(
            name: "Test User",
            email: "test@example.com",
            timezone: timezone
        )

        let pointer = try ObjectFactory.makeSignaturePointer(signature: signature)
        defer { git_signature_free(pointer) }

        let raw = pointer.pointee

        // Offset is stored in minutes
        #expect(raw.when.offset == 180)
    }

    @Test("Convert to raw with negative timezone offset")
    func rawPreservesNegativeTimezone() async throws {
        // UTC-5 timezone (-300 minutes offset)
        let timezone = TimeZone(secondsFromGMT: -5 * 60 * 60)!

        let signature = Signature(
            name: "Test User",
            email: "test@example.com",
            timezone: timezone
        )

        let pointer = try ObjectFactory.makeSignaturePointer(signature: signature)
        defer { git_signature_free(pointer) }

        let raw = pointer.pointee

        #expect(raw.when.offset == -300)
    }

    @Test("Round-trip conversion preserves all values")
    func roundTripConversion() async throws {
        let originalDate = Date(timeIntervalSince1970: 1_700_000_000)
        let originalTimezone = TimeZone(secondsFromGMT: 2 * 60 * 60)!

        let original = Signature(
            name: "Round Trip User",
            email: "roundtrip@example.com",
            date: originalDate,
            timezone: originalTimezone
        )

        // Convert to raw and back
        let pointer = try ObjectFactory.makeSignaturePointer(signature: original)
        defer { git_signature_free(pointer) }

        let converted = Signature(pointer: pointer)

        #expect(converted.name == original.name)
        #expect(converted.email == original.email)
        #expect(converted.date == original.date)
        #expect(converted.timezone == original.timezone)
    }

    @Test("Round-trip with UTC timezone")
    func roundTripUTC() async throws {
        let utc = TimeZone(identifier: "UTC")!

        let original = Signature(
            name: "UTC User",
            email: "utc@example.com",
            date: Date(timeIntervalSince1970: 1_600_000_000),
            timezone: utc
        )

        let pointer = try ObjectFactory.makeSignaturePointer(signature: original)
        defer { git_signature_free(pointer) }

        let converted = Signature(pointer: pointer)

        #expect(converted.timezone.secondsFromGMT() == 0)
    }

    @Test("Signature used in tag preserves values")
    func signatureInTag() async throws {
        let repository = mockRepository()
        let commit = try repository.mockCommit()

        let customTagger = Signature(
            name: "Tag Creator",
            email: "tagger@example.com",
            date: Date(timeIntervalSince1970: 1_700_000_000),
            timezone: TimeZone(secondsFromGMT: 60 * 60)!  // UTC+1
        )

        // Create tag with custom tagger
        let tag = try repository.tag.create(
            named: "v1.0.0",
            target: commit,
            tagger: customTagger,
            message: "Test tag"
        )

        // Retrieve and verify
        let tagger = try #require(tag.tagger)
        #expect(tagger.name == "Tag Creator")
        #expect(tagger.email == "tagger@example.com")
        #expect(tagger.date == Date(timeIntervalSince1970: 1_700_000_000))
    }
}
