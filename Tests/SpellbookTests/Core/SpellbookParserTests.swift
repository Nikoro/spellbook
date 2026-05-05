import Testing
@testable import SpellbookKit

struct SpellbookParserTests {
    private let parser = SpellbookParser()

    @Test func canonicalShorthandSpell_parsesAsScript() throws {
        let node: YAMLNode = .map([
            MapEntry(key: "spells", value: .map([
                MapEntry(key: "hello", value: .scalar("echo \"Hello\""))
            ]))
        ])

        let manifest = try parser.parse(node)

        #expect(manifest == SpellbookManifest(spells: [
            SpellDefinition(name: "hello", script: "echo \"Hello\"")
        ]))
    }

    @Test func compactMode_topLevelSpell() throws {
        let node: YAMLNode = .map([
            MapEntry(key: "hello", value: .scalar("echo hi"))
        ])

        let manifest = try parser.parse(node)

        #expect(manifest.spells == [SpellDefinition(name: "hello", script: "echo hi")])
    }

    @Test func mixedMode_isError_whenSpellsAndTopLevelSpellCoexist() {
        let node: YAMLNode = .map([
            MapEntry(key: "spells", value: .map([
                MapEntry(key: "hello", value: .scalar("echo hi"))
            ])),
            MapEntry(key: "build", value: .scalar("echo build"))
        ])

        let error = #expect(throws: SpellbookError.self) {
            try parser.parse(node)
        }
        guard case .mixedManifestMode = error else {
            Issue.record("expected mixedManifestMode, got \(error)")
            return
        }
    }

    @Test func canonicalMode_withVersionOne() throws {
        let node: YAMLNode = .map([
            MapEntry(key: "version", value: .scalar("1")),
            MapEntry(key: "spells", value: .map([
                MapEntry(key: "hello", value: .scalar("echo hi"))
            ]))
        ])

        let manifest = try parser.parse(node)

        #expect(manifest.version == 1)
    }

    @Test func canonicalMode_unsupportedVersion_isError() {
        let node: YAMLNode = .map([
            MapEntry(key: "version", value: .scalar("2")),
            MapEntry(key: "spells", value: .map([]))
        ])

        let error = #expect(throws: SpellbookError.self) {
            try parser.parse(node)
        }
        guard case .unsupportedManifestVersion = error else {
            Issue.record("expected unsupportedManifestVersion, got \(error)")
            return
        }
    }

    @Test func canonicalMode_extendsIsMetadata() throws {
        let node: YAMLNode = .map([
            MapEntry(key: "extends", value: .scalar("../shared.yaml")),
            MapEntry(key: "spells", value: .map([
                MapEntry(key: "hello", value: .scalar("echo hi"))
            ]))
        ])

        let manifest = try parser.parse(node)

        #expect(manifest.extends == "../shared.yaml")
    }

    @Test func compactMode_extendsIsASpell_notMetadata() throws {
        let node: YAMLNode = .map([
            MapEntry(key: "extends", value: .scalar("echo extending"))
        ])

        let manifest = try parser.parse(node)

        #expect(manifest.extends == nil)
        #expect(manifest.spells == [SpellDefinition(name: "extends", script: "echo extending")])
    }

    @Test func canonicalMode_unknownTopLevelKey_isError() {
        let node: YAMLNode = .map([
            MapEntry(key: "env", value: .map([])),
            MapEntry(key: "spells", value: .map([]))
        ])

        let error = #expect(throws: SpellbookError.self) {
            try parser.parse(node)
        }
        guard case .reservedTopLevelKey = error else {
            Issue.record("expected reservedTopLevelKey, got \(error)")
            return
        }
    }
}
