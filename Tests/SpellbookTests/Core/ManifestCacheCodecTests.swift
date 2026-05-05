import Foundation
import Testing
@testable import SpellbookKit

struct ManifestCacheCodecTests {

    // MARK: round-trip

    @Test func roundTrip_flatSpell() throws {
        let spell = SpellDefinition(name: "hello", description: "say hi", script: "echo hi")
        let manifest = SpellbookManifest(spells: [spell])
        let data = ManifestCacheCodec.encode(manifest: manifest, extendsChain: ["/a/spells.yaml"])
        let decoded = try #require(ManifestCacheCodec.decode(data))
        #expect(decoded.merged == manifest)
        #expect(decoded.extendsChain == ["/a/spells.yaml"])
        #expect(decoded.formatVersion == ManifestCacheCodec.currentFormatVersion)
    }

    @Test func roundTrip_spellWithParamsAndFlags() throws {
        let positional = ParamDefinition(
            name: "env",
            shape: ParamShape(isRequired: true, isPositional: true),
            schema: ParamSchema(type: .string, values: ["staging", "prod"])
        )
        let namedFlag = ParamDefinition(
            name: "verbose",
            description: "noisy",
            shape: ParamShape(isRequired: false, isPositional: false, flags: ["--verbose", "-v"]),
            schema: ParamSchema(type: .bool, defaultValue: "false")
        )
        let body = SpellBody(script: "deploy {{env}}", params: [positional, namedFlag])
        let spell = SpellDefinition(
            identity: SpellIdentity(name: "sbdeploy", aliases: ["dep"]),
            body: body
        )
        let manifest = SpellbookManifest(spells: [spell])
        let data = ManifestCacheCodec.encode(manifest: manifest, extendsChain: [])
        let decoded = try #require(ManifestCacheCodec.decode(data))
        #expect(decoded.merged == manifest)
    }

    @Test func roundTrip_nestedSwitch() throws {
        let inner = SwitchDefinition(options: [
            SwitchOptionDefinition(name: "staging", command: SpellDefinition(name: "stg")),
            SwitchOptionDefinition(name: "prod", command: SpellDefinition(name: "prd"))
        ])
        let deploy = SpellDefinition(
            identity: SpellIdentity(name: "deploy"),
            body: SpellBody(switchBranches: inner)
        )
        let rootSwitch = SwitchDefinition(
            options: [SwitchOptionDefinition(name: "deploy", command: deploy)]
        )
        let root = SpellDefinition(
            identity: SpellIdentity(name: "sb"),
            body: SpellBody(switchBranches: rootSwitch)
        )
        let manifest = SpellbookManifest(spells: [root])
        let data = ManifestCacheCodec.encode(manifest: manifest, extendsChain: [])
        let decoded = try #require(ManifestCacheCodec.decode(data))
        #expect(decoded.merged == manifest)
    }

    @Test func roundTrip_extendsChainLengthThree() throws {
        let paths = ["/a/spells.yaml", "/b/spells.yaml", "/c/spells.yaml"]
        let manifest = SpellbookManifest(spells: [SpellDefinition(name: "x", script: "y")])
        let data = ManifestCacheCodec.encode(manifest: manifest, extendsChain: paths)
        let decoded = try #require(ManifestCacheCodec.decode(data))
        #expect(decoded.extendsChain == paths)
    }

    // MARK: corruption / version

    @Test func decode_rejectsBadMagic() {
        var corrupted = ManifestCacheCodec.encode(
            manifest: SpellbookManifest(spells: []), extendsChain: []
        )
        corrupted[0] = 0x00
        #expect(ManifestCacheCodec.decode(corrupted) == nil)
    }

    @Test func decode_rejectsUnsupportedVersion() {
        let manifest = SpellbookManifest(spells: [SpellDefinition(name: "x", script: "y")])
        var data = ManifestCacheCodec.encode(manifest: manifest, extendsChain: [])
        // magic(4) | formatVersion(u16)  — bump version beyond supported.
        data[4] = 0xFF
        data[5] = 0xFF
        #expect(ManifestCacheCodec.decode(data) == nil)
    }

    @Test func decode_truncatedPayload_returnsNil() {
        let manifest = SpellbookManifest(spells: [SpellDefinition(name: "x", script: "y")])
        var data = ManifestCacheCodec.encode(manifest: manifest, extendsChain: ["/a"])
        data.removeLast(5)
        #expect(ManifestCacheCodec.decode(data) == nil)
    }

    @Test func decode_rejectsUnknownParamTypeCode() throws {
        let param = ParamDefinition(
            name: "count",
            shape: ParamShape(isRequired: true, isPositional: true),
            schema: ParamSchema(type: .int)
        )
        let body = SpellBody(script: "echo {{count}}", params: [param])
        let spell = SpellDefinition(identity: SpellIdentity(name: "x"), body: body)
        let manifest = SpellbookManifest(spells: [spell])
        var data = ManifestCacheCodec.encode(manifest: manifest, extendsChain: [])
        let typeCode = ManifestCacheTypes.paramTypeCode(.int)
        let index = try #require(data.firstIndex(of: typeCode))
        data[index] = 0xFF
        #expect(ManifestCacheCodec.decode(data) == nil)
    }

    @Test func decode_rejectsUnknownDefaultBranchTag() {
        // Manifest with a switch and an explicit "none" default branch (tag 0).
        let option = SwitchOptionDefinition(
            name: "stg", command: SpellDefinition(name: "stg-cmd", script: "ok")
        )
        let switchDef = SwitchDefinition(options: [option], defaultBranch: .none)
        let spell = SpellDefinition(
            identity: SpellIdentity(name: "deploy"),
            body: SpellBody(switchBranches: switchDef)
        )
        let manifest = SpellbookManifest(spells: [spell])
        var data = ManifestCacheCodec.encode(manifest: manifest, extendsChain: [])
        // The DefaultBranch.none tag is byte 0 written immediately after the
        // switch options. Patching every 0x00 would corrupt unrelated data, so
        // walk back from the tail: the encoder writes the branch tag last and
        // only uses 0x00 there for `.none`. The tail byte is the tag.
        data[data.count - 1] = 0xFF
        #expect(ManifestCacheCodec.decode(data) == nil)
    }

    @Test func encode_isDeterministic() {
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(name: "a", script: "x"),
            SpellDefinition(name: "b", script: "y")
        ])
        let first = ManifestCacheCodec.encode(manifest: manifest, extendsChain: ["/a"])
        let second = ManifestCacheCodec.encode(manifest: manifest, extendsChain: ["/a"])
        #expect(first == second)
    }

    // MARK: projectHash

    @Test func projectHash_isSha256Hex_ofAbsolutePath() {
        let hash = ManifestCacheCodec.projectHash(absoluteManifestPath: "/tmp/spells.yaml")
        // SHA-256 hex digest length = 64
        #expect(hash.count == 64)
        #expect(hash.allSatisfy { $0.isHexDigit })
    }

    @Test func projectHash_isStableForSameInput() {
        let first = ManifestCacheCodec.projectHash(absoluteManifestPath: "/tmp/spells.yaml")
        let second = ManifestCacheCodec.projectHash(absoluteManifestPath: "/tmp/spells.yaml")
        #expect(first == second)
    }

    @Test func projectHash_differsForDifferentInputs() {
        let first = ManifestCacheCodec.projectHash(absoluteManifestPath: "/tmp/a.yaml")
        let second = ManifestCacheCodec.projectHash(absoluteManifestPath: "/tmp/b.yaml")
        #expect(first != second)
    }
}
