import Foundation

final class OverflowSink: @unchecked Sendable {
    private let terminal: TerminalProtocol
    private let lock = NSLock()
    private var flushed = false

    init(terminal: TerminalProtocol) {
        self.terminal = terminal
    }

    var didFlush: Bool {
        lock.lock(); defer { lock.unlock() }
        return flushed
    }

    func handle(stdout: [UInt8], stderr: [UInt8]) {
        lock.lock()
        flushed = true
        lock.unlock()
        terminal.clearLine()
        terminal.showCursor()
        terminal.writeError("silent mode disabled \u{2014} output exceeded buffer")
        if let text = Self.asString(stdout) { terminal.write(text) }
        if let text = Self.asString(stderr) { terminal.writeError(text) }
    }

    private static func asString(_ bytes: [UInt8]) -> String? {
        guard !bytes.isEmpty else { return nil }
        return String(bytes: bytes, encoding: .utf8)
    }
}
