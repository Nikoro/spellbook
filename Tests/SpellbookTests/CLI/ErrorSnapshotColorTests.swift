import Testing
@testable import SpellbookKit

struct ErrorSnapshotColorTests {

    @Test func tabIndentation_color() {
        let output = ErrorReporter.render(.tabIndentation(line: 3), color: true)
        Snapshot.assert(output, named: "color-tabIndentation")
    }

    @Test func unmatchedQuote_color() {
        let output = ErrorReporter.render(.unmatchedQuote(line: 5, column: 12), color: true)
        Snapshot.assert(output, named: "color-unmatchedQuote")
    }

    @Test func spellNotFoundWithSuggestions_color() {
        let output = ErrorReporter.render(
            .spellNotFoundWithSuggestions(name: "build", projects: ["/other"]),
            color: true
        )
        Snapshot.assert(output, named: "color-spellNotFoundWithSuggestions")
    }

    @Test func invalidParamValue_color() {
        let output = ErrorReporter.render(
            .invalidParamValue(
                spell: "deploy", param: "count", value: "abc",
                expected: .int, validValues: [], example: "42"
            ),
            color: true
        )
        Snapshot.assert(output, named: "color-invalidParamValue")
    }
}
