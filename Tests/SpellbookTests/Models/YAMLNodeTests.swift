import Testing
@testable import SpellbookKit

struct YAMLNodeTests {
    @Test func scalar_exposesString() {
        let node = YAMLNode.scalar("hello")
        #expect(node.scalar == "hello")
        #expect(node.map == nil)
        #expect(node.sequence == nil)
        #expect(node.isNull == false)
    }

    @Test func null_isNull() {
        #expect(YAMLNode.null.isNull)
    }

    @Test func map_preservesOrder() {
        let entries = [
            MapEntry(key: "first", value: .scalar("1")),
            MapEntry(key: "second", description: "doc", value: .scalar("2"))
        ]
        let node = YAMLNode.map(entries)
        #expect(node.map?.count == 2)
        #expect(node.map?[0].key == "first")
        #expect(node.map?[1].description == "doc")
        #expect(node.map?[1].value.scalar == "2")
    }

    @Test func sequence_holdsNodes() {
        let node = YAMLNode.sequence([.scalar("a"), .scalar("b")])
        #expect(node.sequence?.count == 2)
        #expect(node.sequence?.first?.scalar == "a")
    }

    @Test func equality_isStructural() {
        let left = YAMLNode.map([MapEntry(key: "k", value: .scalar("v"))])
        let right = YAMLNode.map([MapEntry(key: "k", value: .scalar("v"))])
        #expect(left == right)
    }
}
