import Foundation
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

public final class StandardTerminal: TerminalProtocol {
    public let capabilities: TerminalCapabilities
    private let stdout: (Data) -> Void
    private let stderr: (Data) -> Void
    private var savedAttributes: termios?

    public init(
        capabilities: TerminalCapabilities,
        stdout: @escaping (Data) -> Void = { FileHandle.standardOutput.write($0) },
        stderr: @escaping (Data) -> Void = { FileHandle.standardError.write($0) }
    ) {
        self.capabilities = capabilities
        self.stdout = stdout
        self.stderr = stderr
    }

    public func readByte() throws -> UInt8 {
        var byte: UInt8 = 0
        guard read(STDIN_FILENO, &byte, 1) == 1 else {
            throw TerminalReadError.noInput
        }
        return byte
    }

    public func write(_ text: String) { stdout(Data(text.utf8)) }
    public func writeLine(_ text: String) { stdout(Data((text + "\n").utf8)) }
    public func writeError(_ text: String) { stderr(Data(text.utf8)) }

    public func enableRawMode() throws {
        guard capabilities.supportsRawMode else { return }
        var original = termios()
        guard tcgetattr(STDIN_FILENO, &original) == 0 else {
            throw TerminalReadError.rawModeUnavailable
        }
        var raw = original
        cfmakeraw(&raw)
        guard tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw) == 0 else {
            throw TerminalReadError.rawModeUnavailable
        }
        savedAttributes = original
    }

    public func restoreMode() {
        guard var original = savedAttributes else { return }
        savedAttributes = nil
        _ = tcsetattr(STDIN_FILENO, TCSAFLUSH, &original)
    }

    public func clearLine() { write("\u{1B}[2K\r") }
    public func moveCursorUp(_ lines: Int) {
        guard lines > 0 else { return }
        write("\u{1B}[\(lines)A")
    }
    public func hideCursor() { write("\u{1B}[?25l") }
    public func showCursor() { write("\u{1B}[?25h") }
}
