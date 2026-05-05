import Testing
@testable import SpellbookKit

struct TerminalChoiceProviderTests {

    @Test func nonTTY_returnsUnavailable() throws {
        let provider = makeProvider(isTTY: false, supportsRawMode: false)
        let outcome = try provider.choose(options: ["a", "b"], prompt: "pick")
        #expect(outcome == .unavailable)
    }

    @Test func emptyOptions_returnsCancelled() throws {
        let provider = makeProvider(isTTY: true, supportsRawMode: false)
        let outcome = try provider.choose(options: [], prompt: "pick")
        #expect(outcome == .cancelled)
    }

    @Test func dumbTTY_usesNumberedPicker() throws {
        let terminal = MockTerminal(capabilities: TerminalCapabilities(
            isTTY: true, supportsColor: false, supportsRawMode: false
        ))
        terminal.inputBytes = Array("1\n".utf8)
        let provider = TerminalChoiceProvider(terminal: terminal)
        let outcome = try provider.choose(options: ["staging", "production"], prompt: "deploy")
        #expect(outcome == .selected(0))
    }

    @Test func dumbTTY_outOfRange_cancels() throws {
        let terminal = MockTerminal(capabilities: TerminalCapabilities(
            isTTY: true, supportsColor: false, supportsRawMode: false
        ))
        terminal.inputBytes = Array("9\n".utf8)
        let provider = TerminalChoiceProvider(terminal: terminal)
        let outcome = try provider.choose(options: ["a", "b"], prompt: "pick")
        #expect(outcome == .cancelled)
    }

    private func makeProvider(
        isTTY: Bool, supportsRawMode: Bool
    ) -> TerminalChoiceProvider {
        TerminalChoiceProvider(terminal: MockTerminal(
            capabilities: TerminalCapabilities(
                isTTY: isTTY,
                supportsColor: false,
                supportsRawMode: supportsRawMode
            )
        ))
    }
}
