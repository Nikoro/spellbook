import Testing
@testable import SpellbookKit

struct ListResolverTests {

    @Test func emptyManifest_returnsNoEntries() {
        let manifest = SpellbookManifest(spells: [])
        let entries = ListResolver.resolve(manifest)
        #expect(entries.isEmpty)
    }

    @Test func singleSpell_mapsCorrectly() {
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(name: "hello", script: "echo hi")
        ])
        let entries = ListResolver.resolve(manifest)
        #expect(entries.count == 1)
        #expect(entries[0].name == "hello")
        #expect(entries[0].aliases.isEmpty)
        #expect(entries[0].description == nil)
    }

    @Test func spellWithAliases_includesAliases() {
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(
                identity: SpellIdentity(name: "test", aliases: ["t", "tst"]),
                body: SpellBody(script: "swift test")
            )
        ])
        let entries = ListResolver.resolve(manifest)
        #expect(entries[0].aliases == ["t", "tst"])
    }

    @Test func spellWithDescription_includesDescription() {
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(name: "build", description: "Build the project", script: "make")
        ])
        let entries = ListResolver.resolve(manifest)
        #expect(entries[0].description == "Build the project")
    }

    @Test func multipleSpells_preservesOrder() {
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(name: "build", script: "make"),
            SpellDefinition(name: "test", script: "make test"),
            SpellDefinition(name: "clean", script: "make clean")
        ])
        let entries = ListResolver.resolve(manifest)
        #expect(entries.map(\.name) == ["build", "test", "clean"])
    }
}
