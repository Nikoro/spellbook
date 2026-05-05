public protocol TerminalProtocol {
    var capabilities: TerminalCapabilities { get }
    func readByte() throws -> UInt8
    func write(_ text: String)
    func writeLine(_ text: String)
    func writeError(_ text: String)
    func enableRawMode() throws
    func restoreMode()
    func clearLine()
    func moveCursorUp(_ lines: Int)
    func hideCursor()
    func showCursor()
}

extension TerminalProtocol {
    public func withRawMode<T>(
        _ body: () throws -> T
    ) throws -> T {
        try enableRawMode()
        do {
            let result = try body()
            restoreMode()
            return result
        } catch {
            restoreMode()
            throw error
        }
    }
}
