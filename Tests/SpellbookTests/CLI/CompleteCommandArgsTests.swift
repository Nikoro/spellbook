import Testing
@testable import SpellbookKit

struct CompleteCommandArgsTests {

    @Test func parsesWrapperCwordAndTokens() throws {
        let parsed = try CompleteCommandArgs.parse(
            ["sbdeploy", "--cword", "2", "--", "sbdeploy", "staging", ""]
        )
        #expect(parsed.wrapper == "sbdeploy")
        #expect(parsed.cword == 2)
        #expect(parsed.tokens == ["sbdeploy", "staging", ""])
    }

    @Test func rejectsEmptyWrapper() {
        #expect(throws: (any Error).self) {
            try CompleteCommandArgs.parse([])
        }
    }

    @Test func rejectsMissingCword() {
        #expect(throws: (any Error).self) {
            try CompleteCommandArgs.parse(["sbdeploy", "--", "sbdeploy"])
        }
    }

    @Test func rejectsNegativeCword() {
        #expect(throws: (any Error).self) {
            try CompleteCommandArgs.parse(
                ["sbdeploy", "--cword", "-1", "--", "sbdeploy"]
            )
        }
    }

    @Test func rejectsMissingSeparator() {
        #expect(throws: (any Error).self) {
            try CompleteCommandArgs.parse(
                ["sbdeploy", "--cword", "0", "sbdeploy"]
            )
        }
    }

    @Test func acceptsEmptyCursorTokenAfterSeparator() throws {
        let parsed = try CompleteCommandArgs.parse(
            ["hello", "--cword", "1", "--", "hello", ""]
        )
        #expect(parsed.tokens == ["hello", ""])
        #expect(parsed.cword == 1)
    }
}
