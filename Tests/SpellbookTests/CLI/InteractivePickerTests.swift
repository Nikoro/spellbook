import Testing
@testable import SpellbookKit

struct InteractivePickerTests {
    private let options = ["alpha", "beta", "gamma"]

    private func terminal(
        _ bytes: [UInt8]
    ) -> MockTerminal {
        let term = MockTerminal(capabilities: TerminalCapabilities(
            isTTY: true, supportsColor: true, supportsRawMode: true
        ))
        term.inputBytes = bytes
        return term
    }

    // MARK: - Arrow keys

    @Test func arrowDownMovesSelection() throws {
        let term = terminal([0x1B, 0x5B, 0x42, 0x0D])
        let result = try InteractivePicker.pick(
            options: options, prompt: "Pick:", terminal: term
        )
        #expect(result == .selected(1))
    }

    @Test func arrowUpWrapsToLast() throws {
        let term = terminal([0x1B, 0x5B, 0x41, 0x0D])
        let result = try InteractivePicker.pick(
            options: options, prompt: "Pick:", terminal: term
        )
        #expect(result == .selected(2))
    }

    @Test func arrowDownWrapsToFirst() throws {
        // Down 3 times wraps: 0→1→2→0
        let down: [UInt8] = [0x1B, 0x5B, 0x42]
        let term = terminal(down + down + down + [0x0D])
        let result = try InteractivePicker.pick(
            options: options, prompt: "Pick:", terminal: term
        )
        #expect(result == .selected(0))
    }

    // MARK: - j/k keys

    @Test func jMovesDown() throws {
        let term = terminal([0x6A, 0x0D])
        let result = try InteractivePicker.pick(
            options: options, prompt: "Pick:", terminal: term
        )
        #expect(result == .selected(1))
    }

    @Test func kMovesUp() throws {
        let term = terminal([0x6B, 0x0D])
        let result = try InteractivePicker.pick(
            options: options, prompt: "Pick:", terminal: term
        )
        #expect(result == .selected(2))
    }

    // MARK: - Enter

    @Test func enterConfirmsInitialSelection() throws {
        let term = terminal([0x0D])
        let result = try InteractivePicker.pick(
            options: options, prompt: "Pick:", terminal: term
        )
        #expect(result == .selected(0))
    }

    // MARK: - Cancel

    @Test func escCancels() throws {
        let term = terminal([0x1B])
        let result = try InteractivePicker.pick(
            options: options, prompt: "Pick:", terminal: term
        )
        #expect(result == .cancelled)
    }

    @Test func qCancels() throws {
        let term = terminal([0x71])
        let result = try InteractivePicker.pick(
            options: options, prompt: "Pick:", terminal: term
        )
        #expect(result == .cancelled)
    }

    // MARK: - Direct numeric selection

    @Test func digitSelectsDirectly() throws {
        let term = terminal([0x32]) // '2'
        let result = try InteractivePicker.pick(
            options: options, prompt: "Pick:", terminal: term
        )
        #expect(result == .selected(1))
    }

    @Test func digitOutOfRangeIgnored() throws {
        let term = terminal([0x39, 0x0D]) // '9' then Enter
        let result = try InteractivePicker.pick(
            options: options, prompt: "Pick:", terminal: term
        )
        #expect(result == .selected(0))
    }

    // MARK: - Edge cases

    @Test func emptyOptionsReturnsCancelled() throws {
        let term = terminal([])
        let result = try InteractivePicker.pick(
            options: [], prompt: "Pick:", terminal: term
        )
        #expect(result == .cancelled)
    }

    @Test func rawModeEnabledAndRestored() throws {
        let term = terminal([0x0D])
        _ = try InteractivePicker.pick(
            options: options, prompt: "Pick:", terminal: term
        )
        #expect(term.rawModeRestored)
    }

    @Test func cursorRestoredOnConfirm() throws {
        let term = terminal([0x0D])
        _ = try InteractivePicker.pick(
            options: options, prompt: "Pick:", terminal: term
        )
        #expect(term.cursorHidden == false)
    }

    @Test func cursorRestoredOnCancel() throws {
        let term = terminal([0x71])
        _ = try InteractivePicker.pick(
            options: options, prompt: "Pick:", terminal: term
        )
        #expect(term.cursorHidden == false)
    }
}
