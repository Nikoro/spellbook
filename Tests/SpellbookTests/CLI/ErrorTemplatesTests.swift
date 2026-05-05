import Testing
@testable import SpellbookKit

struct ErrorTemplatesTests {

    // MARK: - Plain mode

    @Test func header_plainMode() {
        let result = ErrorTemplates.header("something went wrong", color: false)
        #expect(result == "error: something went wrong")
    }

    @Test func context_plainMode() {
        let result = ErrorTemplates.context("line 5", color: false)
        #expect(result == "  --> line 5")
    }

    @Test func caret_plainMode() {
        let result = ErrorTemplates.caret(column: 3, color: false)
        #expect(result == "        ^")
    }

    @Test func body_alwaysPlain() {
        let result = ErrorTemplates.body("Details here.")
        #expect(result == "  Details here.")
    }

    @Test func suggestion_plainMode() {
        let result = ErrorTemplates.suggestion("Try this instead", color: false)
        #expect(result == "tip: Try this instead")
    }

    @Test func compose_allSections() {
        let result = ErrorTemplates.compose(
            header: "error: bad",
            context: "  --> line 1",
            body: "  Explanation.",
            suggestion: "tip: Fix it"
        )
        #expect(result == "error: bad\n  --> line 1\n  Explanation.\ntip: Fix it")
    }

    @Test func compose_headerOnly() {
        let result = ErrorTemplates.compose(header: "error: simple")
        #expect(result == "error: simple")
    }

    // MARK: - Color mode

    @Test func header_colorMode_containsANSI() {
        let result = ErrorTemplates.header("bad", color: true)
        #expect(result.contains("\u{1B}["))
        #expect(result.contains("error:"))
        #expect(result.contains("bad"))
    }

    @Test func suggestion_colorMode_containsCyan() {
        let result = ErrorTemplates.suggestion("fix it", color: true)
        #expect(result.contains("\u{1B}[36m"))
        #expect(result.contains("tip:"))
    }

    @Test func colorSuppressed_noANSI() {
        let header = ErrorTemplates.header("test", color: false)
        let ctx = ErrorTemplates.context("line 1", color: false)
        let sug = ErrorTemplates.suggestion("fix", color: false)
        let caret = ErrorTemplates.caret(column: 1, color: false)
        for text in [header, ctx, sug, caret] {
            #expect(text.contains("\u{1B}") == false, "ANSI found in: \(text)")
        }
    }
}
