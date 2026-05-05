import Testing
@testable import SpellbookKit

struct SpellLookupTests {

    private let lookup = SpellLookup()

    // MARK: - Canonical name

    @Test func findByCanonicalName() {
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(name: "build", script: "swift build"),
            SpellDefinition(name: "test", script: "swift test")
        ])
        let result = lookup.find(name: "build", in: manifest)
        #expect(result?.name == "build")
    }

    // MARK: - Alias

    @Test func findByAlias() {
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(
                identity: SpellIdentity(name: "build", aliases: ["b"]),
                body: SpellBody(script: "swift build")
            )
        ])
        let result = lookup.find(name: "b", in: manifest)
        #expect(result?.name == "build")
    }

    // MARK: - Not found

    @Test func notFound_returnsNil() {
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(name: "build", script: "swift build")
        ])
        #expect(lookup.find(name: "deploy", in: manifest) == nil)
    }

    // MARK: - Canonical takes precedence over alias

    @Test func canonicalNameMatchesBeforeAlias() {
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(
                identity: SpellIdentity(name: "a", aliases: ["b"]),
                body: SpellBody(script: "first")
            ),
            SpellDefinition(
                identity: SpellIdentity(name: "b"),
                body: SpellBody(script: "second")
            )
        ])
        let result = lookup.find(name: "b", in: manifest)
        #expect(result?.script == "second")
    }

    // MARK: - Empty manifest

    @Test func emptyManifest_returnsNil() {
        let manifest = SpellbookManifest(spells: [])
        #expect(lookup.find(name: "anything", in: manifest) == nil)
    }
}
