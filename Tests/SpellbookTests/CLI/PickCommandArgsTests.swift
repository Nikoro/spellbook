import Testing
@testable import SpellbookKit

struct PickCommandArgsTests {

    @Test func candidatesFromStdin_areNewlineDelimited() {
        let raw = "alpha\nbeta\ngamma\n"
        #expect(PickCommandArgs.parseStdin(raw) == ["alpha", "beta", "gamma"])
    }

    @Test func parseStdin_skipsEmptyLines() {
        let raw = "alpha\n\nbeta\n\n"
        #expect(PickCommandArgs.parseStdin(raw) == ["alpha", "beta"])
    }

    @Test func parseStdin_handlesMissingTrailingNewline() {
        let raw = "alpha\nbeta"
        #expect(PickCommandArgs.parseStdin(raw) == ["alpha", "beta"])
    }

    @Test func parseStdin_stripsCarriageReturn() {
        let raw = "alpha\r\nbeta\r\n"
        #expect(PickCommandArgs.parseStdin(raw) == ["alpha", "beta"])
    }
}
