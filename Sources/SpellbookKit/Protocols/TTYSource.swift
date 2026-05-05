public protocol TTYSource {
    mutating func enterRawMode() throws
    mutating func restoreMode()
    func readByte() throws -> UInt8?
    func write(_ string: String)
    var isTTY: Bool { get }
}
