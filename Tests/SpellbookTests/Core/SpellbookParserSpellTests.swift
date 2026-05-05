import Testing
@testable import SpellbookKit

struct SpellbookParserSpellTests {
    private let parser = SpellbookParser()

    @Test func canonicalMapSpell_withScriptKey() throws {
        let node = canonicalSingleSpell(name: "hello", fields: [
            MapEntry(key: "script", value: .scalar("echo Hi"))
        ])

        let manifest = try parser.parse(node)

        #expect(manifest.spells == [SpellDefinition(name: "hello", script: "echo Hi")])
    }

    @Test func canonicalSpell_descriptionFromDoubleHashComment() throws {
        let node: YAMLNode = .map([
            MapEntry(key: "spells", value: .map([
                MapEntry(key: "hello", description: "Say hi", value: .scalar("echo hi"))
            ]))
        ])

        let manifest = try parser.parse(node)

        #expect(manifest.spells == [SpellDefinition(name: "hello", description: "Say hi", script: "echo hi")])
    }

    @Test func canonicalSpell_explicitDescriptionOverridesComment() throws {
        let node: YAMLNode = .map([
            MapEntry(key: "spells", value: .map([
                MapEntry(
                    key: "hello",
                    description: "From comment",
                    value: .map([
                        MapEntry(key: "description", value: .scalar("From field")),
                        MapEntry(key: "script", value: .scalar("echo hi"))
                    ])
                )
            ]))
        ])

        let manifest = try parser.parse(node)

        #expect(manifest.spells.first?.description == "From field")
    }

    @Test func spellMap_runtimeFields_overrideSilentWorkingDirShell() throws {
        let node = canonicalSingleSpell(name: "ls", fields: [
            MapEntry(key: "script", value: .scalar("ls -la")),
            MapEntry(key: "override", value: .scalar("true")),
            MapEntry(key: "silent", value: .scalar("true")),
            MapEntry(key: "working_dir", value: .scalar("..")),
            MapEntry(key: "shell", value: .scalar("zsh"))
        ])

        let spell = try #require(try parser.parse(node).spells.first)

        #expect(spell.override)
        #expect(spell.silent)
        #expect(spell.workingDir == "..")
        #expect(spell.shell == "zsh")
    }

    @Test func spellMap_defaultsForOmittedFields() throws {
        let node = canonicalSingleSpell(name: "hello", fields: [
            MapEntry(key: "script", value: .scalar("echo hi"))
        ])

        let spell = try #require(try parser.parse(node).spells.first)

        #expect(spell.override == false)
        #expect(spell.silent == false)
        #expect(spell.workingDir == nil)
        #expect(spell.shell == nil)
        #expect(spell.aliases.isEmpty)
    }

    @Test func spellMap_aliases_acceptCommaSeparatedString() throws {
        let node = canonicalSingleSpell(name: "build", fields: [
            MapEntry(key: "script", value: .scalar("make")),
            MapEntry(key: "aliases", value: .scalar("b, bld"))
        ])

        let spell = try #require(try parser.parse(node).spells.first)

        #expect(spell.aliases == ["b", "bld"])
    }

    @Test func spellMap_aliases_acceptFlowSequence() throws {
        let node = canonicalSingleSpell(name: "build", fields: [
            MapEntry(key: "script", value: .scalar("make")),
            MapEntry(key: "aliases", value: .sequence([.scalar("b"), .scalar("bld")]))
        ])

        let spell = try #require(try parser.parse(node).spells.first)

        #expect(spell.aliases == ["b", "bld"])
    }

    private func canonicalSingleSpell(name: String, fields: [MapEntry]) -> YAMLNode {
        .map([
            MapEntry(key: "spells", value: .map([
                MapEntry(key: name, value: .map(fields))
            ]))
        ])
    }
}
