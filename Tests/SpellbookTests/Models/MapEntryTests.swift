import Testing
@testable import SpellbookKit

struct MapEntryTests {
    @Test func init_defaultsDescriptionToNil() {
        let entry = MapEntry(key: "name", value: .scalar("v"))
        #expect(entry.key == "name")
        #expect(entry.description == nil)
        #expect(entry.value == .scalar("v"))
    }

    @Test func init_capturesDescription() {
        let entry = MapEntry(key: "k", description: "docs here", value: .null)
        #expect(entry.description == "docs here")
    }

    @Test func equatable_comparesAllFields() {
        let first = MapEntry(key: "k", description: "d", value: .scalar("v"))
        let second = MapEntry(key: "k", description: "d", value: .scalar("v"))
        #expect(first == second)
    }
}
