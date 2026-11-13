import Testing
@testable import SpellbookKit

struct FiniteChoicePickerTests {
    private let options = ["alpha", "beta", "gamma"]

    @Test func nonTTYReturnsUnavailable() throws {
        let caps = TerminalCapabilities(
            isTTY: false,
            supportsColor: false,
            supportsRawMode: false
        )
        let term = MockTerminal(capabilities: caps)
        let result = try FiniteChoicePicker.pick(
            options: options, prompt: "Pick:", terminal: term
        )
        #expect(result == .unavailable)
    }

    @Test func nonTTYDoesNotWrite() throws {
        let caps = TerminalCapabilities(
            isTTY: false,
            supportsColor: false,
            supportsRawMode: false
        )
        let term = MockTerminal(capabilities: caps)
        _ = try FiniteChoicePicker.pick(
            options: options, prompt: "Pick:", terminal: term
        )
        #expect(term.writtenLines.isEmpty)
    }

    @Test func dumbTerminalUsesNumberedPicker() throws {
        let caps = TerminalCapabilities(
            isTTY: true,
            supportsColor: false,
            supportsRawMode: false
        )
        let term = MockTerminal(capabilities: caps)
        term.inputBytes = Array("2".utf8) + [0x0A]
        let result = try FiniteChoicePicker.pick(
            options: options, prompt: "Pick:", terminal: term
        )
        #expect(result == .selected(1))
        #expect(term.rawModeEnabled == false)
        #expect(term.rawModeRestored == false)
    }

    @Test func dumbTerminalShowsNumberedOutput() throws {
        let caps = TerminalCapabilities(
            isTTY: true,
            supportsColor: false,
            supportsRawMode: false
        )
        let term = MockTerminal(capabilities: caps)
        term.inputBytes = Array("1".utf8) + [0x0A]
        _ = try FiniteChoicePicker.pick(
            options: options, prompt: "Pick:", terminal: term
        )
        #expect(term.writtenLines.contains("  1) alpha"))
    }

    @Test func normalTTYDelegatesToInteractivePicker() throws {
        let caps = TerminalCapabilities(
            isTTY: true,
            supportsColor: true,
            supportsRawMode: true
        )
        let term = MockTerminal(capabilities: caps)
        term.inputBytes = [0x0D]
        let result = try FiniteChoicePicker.pick(
            options: options, prompt: "Pick:", terminal: term
        )
        #expect(result == .selected(0))
        #expect(term.rawModeRestored)
    }

    @Test func normalTTYCancelMapsCorrectly() throws {
        let caps = TerminalCapabilities(
            isTTY: true,
            supportsColor: true,
            supportsRawMode: true
        )
        let term = MockTerminal(capabilities: caps)
        term.inputBytes = [0x71]
        let result = try FiniteChoicePicker.pick(
            options: options, prompt: "Pick:", terminal: term
        )
        #expect(result == .cancelled)
    }

    @Test func emptyOptionsReturnsCancelled() throws {
        let caps = TerminalCapabilities(
            isTTY: true,
            supportsColor: true,
            supportsRawMode: true
        )
        let term = MockTerminal(capabilities: caps)
        let result = try FiniteChoicePicker.pick(
            options: [], prompt: "Pick:", terminal: term
        )
        #expect(result == .cancelled)
    }
}
