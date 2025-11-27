import Testing
import libgit2

@testable import SwiftGitX

@Suite("OID Tests", .tags(.oid, .model))
final class OIDTests: SwiftGitXTest {
    @Test("Initialize OID from hex string")
    func initFromHex() async throws {
        let shaHex = "42a02b346bb0fb0db7eff3cffeb3c70babbd2045"
        let oid = try OID(hex: shaHex)

        #expect(oid.hex == shaHex)
    }

    @Test("OID abbreviated returns first 8 characters")
    func abbreviated() async throws {
        let shaHex = "42a02b346bb0fb0db7eff3cffeb3c70babbd2045"
        let oid = try OID(hex: shaHex)

        #expect(oid.abbreviated == "42a02b34")
    }

    @Test("OID round-trip conversion to raw and back")
    func roundTripRaw() async throws {
        let shaHex = "42a02b346bb0fb0db7eff3cffeb3c70babbd2045"
        let oid = try OID(hex: shaHex)

        let raw = oid.raw
        let converted = OID(raw: raw)

        #expect(oid == converted)
        #expect(oid.abbreviated == converted.abbreviated)
        #expect(oid.hex == converted.hex)
    }

    @Test("OID matches libgit2 raw OID")
    func matchesLibgit2Raw() async throws {
        let shaHex = "42a02b346bb0fb0db7eff3cffeb3c70babbd2045"
        let oid = try OID(hex: shaHex)

        var rawOID = git_oid()
        git_oid_fromstr(&rawOID, shaHex)

        #expect(oid == OID(raw: rawOID))
    }

    @Test("Zero OID has all zeros")
    func zeroOID() async throws {
        let zeroOID = OID.zero

        #expect(zeroOID.hex == "0000000000000000000000000000000000000000")
        #expect(zeroOID.abbreviated == "00000000")
    }

    @Test("Zero OID is recognized by libgit2")
    func zeroOIDLibgit2() async throws {
        var zeroOIDRaw = OID.zero.raw

        #expect(git_oid_is_zero(&zeroOIDRaw) == 1)
    }

    @Test("Zero OID equals .zero static property")
    func zeroOIDEquality() async throws {
        let zeroOID = OID.zero

        #expect(zeroOID == .zero)
    }
}
