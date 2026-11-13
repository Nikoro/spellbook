import Testing
@testable import SpellbookKit

struct TerminalCapabilityResolverTests {

    @Test func tty_enablesAllCapabilities() {
        let caps = TerminalCapabilityResolver.resolve(
            isTTY: true, noColorValue: nil, termValue: "xterm-256color"
        )

        #expect(caps.isTTY)
        #expect(caps.supportsColor)
        #expect(caps.supportsRawMode)
    }

    @Test func nonTTY_disablesColorAndRawMode() {
        let caps = TerminalCapabilityResolver.resolve(
            isTTY: false, noColorValue: nil, termValue: "xterm-256color"
        )

        #expect(caps.isTTY == false)
        #expect(caps.supportsColor == false)
        #expect(caps.supportsRawMode == false)
    }

    @Test func noColor_set_disablesColor() {
        let caps = TerminalCapabilityResolver.resolve(
            isTTY: true, noColorValue: "", termValue: "xterm-256color"
        )

        #expect(caps.isTTY)
        #expect(caps.supportsColor == false)
        #expect(caps.supportsRawMode)
    }

    @Test func noColor_nonEmpty_disablesColor() {
        let caps = TerminalCapabilityResolver.resolve(
            isTTY: true, noColorValue: "1", termValue: "xterm-256color"
        )

        #expect(caps.supportsColor == false)
    }

    @Test func termDumb_disablesColorAndRawMode() {
        let caps = TerminalCapabilityResolver.resolve(
            isTTY: true, noColorValue: nil, termValue: "dumb"
        )

        #expect(caps.isTTY)
        #expect(caps.supportsColor == false)
        #expect(caps.supportsRawMode == false)
    }

    @Test func termNil_treatsAsNormal() {
        let caps = TerminalCapabilityResolver.resolve(
            isTTY: true, noColorValue: nil, termValue: nil
        )

        #expect(caps.supportsColor)
        #expect(caps.supportsRawMode)
    }

    @Test func nonTTY_ignoresTermAndNoColor() {
        let caps = TerminalCapabilityResolver.resolve(
            isTTY: false, noColorValue: nil, termValue: nil
        )

        #expect(caps.supportsColor == false)
        #expect(caps.supportsRawMode == false)
    }

    @Test func noColor_and_dumb_disablesBoth() {
        let caps = TerminalCapabilityResolver.resolve(
            isTTY: true, noColorValue: "1", termValue: "dumb"
        )

        #expect(caps.supportsColor == false)
        #expect(caps.supportsRawMode == false)
    }

    @Test func withRawMode_restoresOnNormalCompletion() throws {
        let terminal = MockTerminal(capabilities: ttyCapabilities())

        let result = try terminal.withRawMode { 42 }

        #expect(result == 42)
        #expect(terminal.rawModeRestored)
        #expect(terminal.rawModeEnabled == false)
    }

    @Test func withRawMode_restoresOnError() {
        let terminal = MockTerminal(capabilities: ttyCapabilities())

        #expect(throws: TestError.simulated) {
            try terminal.withRawMode { throw TestError.simulated }
        }
        #expect(terminal.rawModeRestored)
        #expect(terminal.rawModeEnabled == false)
    }

    @Test func withRawMode_propagatesEnableError() {
        let terminal = MockTerminal(capabilities: ttyCapabilities())
        terminal.enableRawModeError = TestError.simulated

        #expect(throws: TestError.simulated) {
            try terminal.withRawMode { 0 }
        }
        #expect(terminal.rawModeRestored == false)
    }

    private func ttyCapabilities() -> TerminalCapabilities {
        TerminalCapabilities(
            isTTY: true, supportsColor: true, supportsRawMode: true
        )
    }

    private enum TestError: Error {
        case simulated
    }
}
