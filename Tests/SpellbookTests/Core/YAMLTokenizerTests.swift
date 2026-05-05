import Testing
@testable import SpellbookKit

struct YAMLTokenizerTests {
    private let tokenizer = YAMLTokenizer()

    @Test func emptySource_returnsNoLines() throws {
        #expect(try tokenizer.tokenize("") == [])
    }

    @Test func singleMapping_capturesIndentAndContent() throws {
        let lines = try tokenizer.tokenize("name: hello")
        #expect(lines == [
            YAMLLine(number: 1, indent: 0, kind: .mapping(content: "name: hello", description: nil))
        ])
    }

    @Test func leadingSpaces_becomeIndent() throws {
        let lines = try tokenizer.tokenize("    script: echo hi")
        #expect(lines.first?.indent == 4)
    }

    @Test func hashComment_isDroppedButKeyRemains() throws {
        let lines = try tokenizer.tokenize("name: hello # trailing")
        #expect(lines.first?.kind == .mapping(content: "name: hello", description: nil))
    }

    @Test func doubleHashComment_isCapturedAsDescription() throws {
        let lines = try tokenizer.tokenize("name: hello ## a greeting")
        #expect(lines.first?.kind == .mapping(content: "name: hello", description: "a greeting"))
    }

    @Test func commentOnlyLine_isDropped() throws {
        #expect(try tokenizer.tokenize("# only a comment") == [])
    }

    @Test func blankLine_isDropped() throws {
        let lines = try tokenizer.tokenize("\n\nname: hi\n\n")
        #expect(lines.count == 1)
        #expect(lines.first?.number == 3)
    }

    @Test func hashInsideDoubleQuotes_isPreserved() throws {
        let source = "token: \"#value\" # comment"
        let lines = try tokenizer.tokenize(source)
        #expect(lines.first?.kind == .mapping(content: "token: \"#value\"", description: nil))
    }

    @Test func hashInsideSingleQuotes_isPreserved() throws {
        let lines = try tokenizer.tokenize("note: '# not a comment'")
        #expect(lines.first?.kind == .mapping(content: "note: '# not a comment'", description: nil))
    }

    @Test func tabIndent_isError() {
        let error = #expect(throws: SpellbookError.self) {
            try tokenizer.tokenize("\tname: hi")
        }
        guard case .tabIndentation(let line) = error else {
            Issue.record("expected tabIndentation")
            return
        }
#expect(line == 1)
    }

    @Test func blockScalar_bodyLinesAreVerbatim() throws {
        let source = """
        script: |
          line one
          # not a comment inside block
          line two
        name: after
        """
        let lines = try tokenizer.tokenize(source)
        let kinds = lines.map { $0.kind }
        #expect(kinds[0] == .mapping(content: "script: |", description: nil))
        #expect(kinds[1] == .blockScalarBody(raw: "  line one"))
        #expect(kinds[2] == .blockScalarBody(raw: "  # not a comment inside block"))
        #expect(kinds[3] == .blockScalarBody(raw: "  line two"))
        #expect(kinds[4] == .mapping(content: "name: after", description: nil))
    }

    @Test func unmatchedDoubleQuote_isError() {
        let error = #expect(throws: SpellbookError.self) {
            try tokenizer.tokenize("name: \"hello")
        }
        guard case .unmatchedQuote = error else {
            Issue.record("expected unmatchedQuote")
            return
        }
    }
}
