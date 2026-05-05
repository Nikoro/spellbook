import Testing
@testable import SpellbookKit

struct ExtendsMergeTests {
    @Test func merge_childOverridesParentSpell() {
        let parent = SpellbookManifest(spells: [
            SpellDefinition(name: "build", script: "./parent-build"),
            SpellDefinition(name: "deploy", script: "./parent-deploy")
        ])
        let child = SpellbookManifest(spells: [
            SpellDefinition(name: "build", script: "./child-build")
        ])

        let merged = ExtendsMerge.closerWins(child: child, parent: parent)

        #expect(merged.spells.map(\.name) == ["build", "deploy"])
        #expect(merged.spells.first { $0.name == "build" }?.script == "./child-build")
    }

    @Test func merge_parentOnlySpellsAreKept() {
        let parent = SpellbookManifest(spells: [
            SpellDefinition(name: "format", script: "./fmt")
        ])
        let child = SpellbookManifest(spells: [])

        let merged = ExtendsMerge.closerWins(child: child, parent: parent)

        #expect(merged.spells.map(\.name) == ["format"])
    }

    @Test func merge_preservesChildOrderBeforeParentOnlySpells() {
        let parent = SpellbookManifest(spells: [
            SpellDefinition(name: "a", script: "./pa"),
            SpellDefinition(name: "b", script: "./pb"),
            SpellDefinition(name: "c", script: "./pc")
        ])
        let child = SpellbookManifest(spells: [
            SpellDefinition(name: "b", script: "./cb"),
            SpellDefinition(name: "d", script: "./cd")
        ])

        let merged = ExtendsMerge.closerWins(child: child, parent: parent)

        #expect(merged.spells.map(\.name) == ["b", "d", "a", "c"])
    }
}
