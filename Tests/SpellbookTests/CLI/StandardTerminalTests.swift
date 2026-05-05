import Foundation
import Testing
@testable import SpellbookKit

struct StandardTerminalTests {

    // MARK: - ANSI output

    @Test func hideCursor_writesANSISequence() {
        let sut = makeSUT()
        sut.terminal.hideCursor()
        #expect(sut.stdout() == "\u{1B}[?25l")
    }

    @Test func showCursor_writesANSISequence() {
        let sut = makeSUT()
        sut.terminal.showCursor()
        #expect(sut.stdout() == "\u{1B}[?25h")
    }

    @Test func clearLine_writesEraseAndCarriageReturn() {
        let sut = makeSUT()
        sut.terminal.clearLine()
        #expect(sut.stdout() == "\u{1B}[2K\r")
    }

    @Test func moveCursorUp_writesCursorUpSequence() {
        let sut = makeSUT()
        sut.terminal.moveCursorUp(3)
        #expect(sut.stdout() == "\u{1B}[3A")
    }

    @Test func moveCursorUp_zeroLines_emitsNothing() {
        let sut = makeSUT()
        sut.terminal.moveCursorUp(0)
        #expect(sut.stdout() == "")
    }

    @Test func moveCursorUp_negativeLines_emitsNothing() {
        let sut = makeSUT()
        sut.terminal.moveCursorUp(-1)
        #expect(sut.stdout() == "")
    }

    // MARK: - Basic writes

    @Test func write_sendsUtf8ToStdout() {
        let sut = makeSUT()
        sut.terminal.write("hello")
        #expect(sut.stdout() == "hello")
    }

    @Test func writeLine_appendsNewline() {
        let sut = makeSUT()
        sut.terminal.writeLine("hi")
        #expect(sut.stdout() == "hi\n")
    }

    @Test func writeError_sendsToStderrNotStdout() {
        let sut = makeSUT()
        sut.terminal.writeError("boom")
        #expect(sut.stderr() == "boom")
        #expect(sut.stdout() == "")
    }

    // MARK: - Raw mode guard

    @Test func enableRawMode_noopWhenCapabilityOff() throws {
        let sut = makeSUT(supportsRawMode: false)
        try sut.terminal.enableRawMode()
        sut.terminal.restoreMode()
    }

    // MARK: - Helpers

    private struct SUT {
        let terminal: StandardTerminal
        let stdoutBuffer: Buffer
        let stderrBuffer: Buffer

        func stdout() -> String { stdoutBuffer.string() }
        func stderr() -> String { stderrBuffer.string() }
    }

    private final class Buffer {
        private var data = Data()

        func append(_ chunk: Data) { data.append(chunk) }
        func string() -> String { String(data: data, encoding: .utf8) ?? "" }
    }

    private func makeSUT(supportsRawMode: Bool = true) -> SUT {
        let stdoutBuffer = Buffer()
        let stderrBuffer = Buffer()
        let terminal = StandardTerminal(
            capabilities: TerminalCapabilities(
                isTTY: true,
                supportsColor: true,
                supportsRawMode: supportsRawMode
            ),
            stdout: { stdoutBuffer.append($0) },
            stderr: { stderrBuffer.append($0) }
        )
        return SUT(
            terminal: terminal,
            stdoutBuffer: stdoutBuffer,
            stderrBuffer: stderrBuffer
        )
    }
}
