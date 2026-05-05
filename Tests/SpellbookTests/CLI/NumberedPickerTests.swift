import Testing
@testable import SpellbookKit

struct NumberedPickerTests {
    private let options = ["alpha", "beta", "gamma"]

    private func terminal(
        _ input: String,
        isTTY: Bool = true
    ) -> MockTerminal {
        let caps = TerminalCapabilities(
            isTTY: isTTY,
            supportsColor: false,
            supportsRawMode: false
        )
        let term = MockTerminal(capabilities: caps)
        term.inputBytes = Array(input.utf8) + [0x0A]
        return term
    }

    // MARK: - Valid selection

    @Test func validNumberSelectsOption() {
        let term = terminal("2")
        let result = NumberedPicker.pick(
            options: options, prompt: "Choose:", terminal: term
        )
        #expect(result == .selected(1))
    }

    @Test func firstOptionSelectable() {
        let term = terminal("1")
        let result = NumberedPicker.pick(
            options: options, prompt: "Choose:", terminal: term
        )
        #expect(result == .selected(0))
    }

    @Test func lastOptionSelectable() {
        let term = terminal("3")
        let result = NumberedPicker.pick(
            options: options, prompt: "Choose:", terminal: term
        )
        #expect(result == .selected(2))
    }

    // MARK: - Invalid input

    @Test func zeroCancels() {
        let term = terminal("0")
        let result = NumberedPicker.pick(
            options: options, prompt: "Choose:", terminal: term
        )
        #expect(result == .cancelled)
    }

    @Test func outOfRangeCancels() {
        let term = terminal("9")
        let result = NumberedPicker.pick(
            options: options, prompt: "Choose:", terminal: term
        )
        #expect(result == .cancelled)
    }

    @Test func nonNumericCancels() {
        let term = terminal("abc")
        let result = NumberedPicker.pick(
            options: options, prompt: "Choose:", terminal: term
        )
        #expect(result == .cancelled)
    }

    @Test func emptyInputCancels() {
        let caps = TerminalCapabilities(
            isTTY: true, supportsColor: false, supportsRawMode: false
        )
        let term = MockTerminal(capabilities: caps)
        term.inputBytes = [0x0A]
        let result = NumberedPicker.pick(
            options: options, prompt: "Choose:", terminal: term
        )
        #expect(result == .cancelled)
    }

    // MARK: - Edge cases

    @Test func emptyOptionsReturnsCancelled() {
        let term = terminal("1")
        let result = NumberedPicker.pick(
            options: [], prompt: "Choose:", terminal: term
        )
        #expect(result == .cancelled)
    }

    @Test func eOFCancels() {
        let caps = TerminalCapabilities(
            isTTY: true, supportsColor: false, supportsRawMode: false
        )
        let term = MockTerminal(capabilities: caps)
        term.inputBytes = []
        let result = NumberedPicker.pick(
            options: options, prompt: "Choose:", terminal: term
        )
        #expect(result == .cancelled)
    }

    // MARK: - Output format

    @Test func rendersNumberedOptions() {
        let term = terminal("1")
        _ = NumberedPicker.pick(
            options: options, prompt: "Choose:", terminal: term
        )
        #expect(term.writtenLines[0] == "Choose:")
        #expect(term.writtenLines[1] == "  1) alpha")
        #expect(term.writtenLines[2] == "  2) beta")
        #expect(term.writtenLines[3] == "  3) gamma")
        #expect(term.writtenLines[4] == "Enter number (1-3):")
    }
}
