@testable import SpellbookKit

public final class MockTerminal: TerminalProtocol {
    public var capabilities: TerminalCapabilities
    public var inputBytes: [UInt8] = []
    public private(set) var written: [String] = []
    public private(set) var writtenLines: [String] = []
    public private(set) var writtenErrors: [String] = []
    public private(set) var rawModeEnabled = false
    public private(set) var rawModeRestored = false
    public private(set) var cursorHidden = false
    public private(set) var linesCleared = 0
    public private(set) var cursorUpMoves: [Int] = []
    public var enableRawModeError: Error?

    private var readIndex = 0

    public init(capabilities: TerminalCapabilities) {
        self.capabilities = capabilities
    }

    public func readByte() throws -> UInt8 {
        guard readIndex < inputBytes.count else {
            throw ReadError.noMoreInput
        }
        let byte = inputBytes[readIndex]
        readIndex += 1
        return byte
    }

    public func write(_ text: String) {
        written.append(text)
    }

    public func writeLine(_ text: String) {
        writtenLines.append(text)
    }

    public func writeError(_ text: String) {
        writtenErrors.append(text)
    }

    public func enableRawMode() throws {
        if let error = enableRawModeError { throw error }
        rawModeEnabled = true
        rawModeRestored = false
    }

    public func restoreMode() {
        rawModeEnabled = false
        rawModeRestored = true
    }

    public func clearLine() {
        linesCleared += 1
    }

    public func moveCursorUp(_ lines: Int) {
        cursorUpMoves.append(lines)
    }

    public func hideCursor() {
        cursorHidden = true
    }

    public func showCursor() {
        cursorHidden = false
    }

    public enum ReadError: Error {
        case noMoreInput
    }
}
