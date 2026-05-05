import Testing
@testable import SpellbookKit

struct YAMLParserTests {
    private let tokenizer = YAMLTokenizer()
    private let parser = YAMLParser()

    private func parse(_ source: String) throws -> YAMLNode {
        try parser.parse(tokenizer.tokenize(source))
    }

    @Test func emptySource_yieldsNull() throws {
        #expect(try parse("") == .null)
    }

    @Test func singleScalarMapping() throws {
        let node = try parse("name: hello")
        #expect(node == .map([MapEntry(key: "name", value: .scalar("hello"))]))
    }

    @Test func mapping_preservesDescriptionFromDoubleHash() throws {
        let node = try parse("name: hi ## greeting")
        #expect(node == .map([MapEntry(key: "name", description: "greeting", value: .scalar("hi"))]))
    }

    @Test func nestedMap_usesDeeperIndent() throws {
        let source = """
        spells:
          hello:
            script: echo hi
        """
        let inner = YAMLNode.map([
            MapEntry(key: "script", value: .scalar("echo hi"))
        ])
        let middle = YAMLNode.map([MapEntry(key: "hello", value: inner)])
        let root = YAMLNode.map([MapEntry(key: "spells", value: middle)])
        #expect(try parse(source) == root)
    }

    @Test func emptyValue_yieldsNullNode() throws {
        let node = try parse("override:")
        #expect(node == .map([MapEntry(key: "override", value: .null)]))
    }

    @Test func blockScalar_joinsLinesAndStripsIndent() throws {
        let source = """
        script: |
          echo hi
          exit 0
        """
        let expected = YAMLNode.map([
            MapEntry(key: "script", value: .scalar("echo hi\nexit 0"))
        ])
        #expect(try parse(source) == expected)
    }

    @Test func inlineFlowSequence_parsesScalars() throws {
        let node = try parse("values: [one, two, three]")
        let expected = YAMLNode.map([
            MapEntry(key: "values", value: .sequence([.scalar("one"), .scalar("two"), .scalar("three")]))
        ])
        #expect(node == expected)
    }

    @Test func inlineFlowSequence_preservesQuotedCommas() throws {
        let node = try parse(#"items: ["a,b", 'c,d']"#)
        let expected = YAMLNode.map([
            MapEntry(key: "items", value: .sequence([.scalar("a,b"), .scalar("c,d")]))
        ])
        #expect(node == expected)
    }

    @Test func scalarBlockSequence_parsesDashItems() throws {
        let source = """
        flags:
          - -n
          - --name
        """
        let expected = YAMLNode.map([
            MapEntry(key: "flags", value: .sequence([.scalar("-n"), .scalar("--name")]))
        ])
        #expect(try parse(source) == expected)
    }

    @Test func sequenceWithMapItem_isError() {
        let source = """
        items:
          - key: val
        """
        let error = #expect(throws: SpellbookError.self) {
            try parse(source)
        }
        guard case .unsupportedSequenceItem = error else {
            Issue.record("expected unsupportedSequenceItem, got \(error)")
            return
        }
    }

    @Test func unexpectedDeeperIndent_isError() {
        let source = """
        name: hi
            extra: x
        """
        let error = #expect(throws: SpellbookError.self) {
            try parse(source)
        }
        guard case .unexpectedIndent = error else {
            Issue.record("expected unexpectedIndent, got \(error)")
            return
        }
    }

    @Test func quotedString_isUnquoted() throws {
        let node = try parse("name: \"hello world\"")
        #expect(node == .map([MapEntry(key: "name", value: .scalar("hello world"))]))
    }

    @Test func missingColonOnMappingLine_isError() {
        let error = #expect(throws: SpellbookError.self) {
            try parse("justakey")
        }
        guard case .missingColon = error else {
            Issue.record("expected missingColon, got \(error)")
            return
        }
    }

    @Test func unclosedFlowSequence_isError() {
        let error = #expect(throws: SpellbookError.self) {
            try parse("values: [one, two")
        }
        guard case .unclosedFlowSequence = error else {
            Issue.record("expected unclosedFlowSequence, got \(error)")
            return
        }
    }
}
