import Testing
@testable import SpellbookKit

struct CompletionLineFormatterTests {

    @Test func emptyCandidates_emitsNoLines() {
        let out = CompletionLineFormatter.format([])
        #expect(out.isEmpty)
    }

    @Test func fallthrough_emitsSentinelLine() {
        let out = CompletionLineFormatter.format([.endOfGrammarFallThrough])
        #expect(out == ["__SPELLBOOK_FALLTHROUGH__"])
    }

    @Test func candidateLineUsesTabSeparator() {
        let candidate = CompletionCandidate(
            value: "--env", kind: .namedFlag,
            description: "target env", needsValueNext: true
        )
        let out = CompletionLineFormatter.format([candidate])
        #expect(out.count == 1)
        let parts = out[0].split(separator: "\t", omittingEmptySubsequences: false)
        #expect(parts[0] == "--env")
        #expect(parts[1] == "namedFlag")
        #expect(parts[2] == "1")
        #expect(parts[3] == "target env")
    }

    @Test func candidateWithoutDescription_emitsEmptyDescription() {
        let candidate = CompletionCandidate(value: "build", kind: .switchOption)
        let out = CompletionLineFormatter.format([candidate])
        let parts = out[0].split(separator: "\t", omittingEmptySubsequences: false)
        #expect(parts[3] == "")
    }
}
