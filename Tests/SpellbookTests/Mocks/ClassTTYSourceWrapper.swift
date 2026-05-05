@testable import SpellbookKit

struct ClassTTYSourceWrapper: TTYSource {
    let inner: MutableTTYSource

    var isTTY: Bool { inner.isTTY }

    mutating func enterRawMode() throws { inner.rawEntered = true }

    mutating func restoreMode() { inner.rawRestored = true }

    func readByte() throws -> UInt8? {
        guard !inner.queue.isEmpty else { return nil }
        return inner.queue.removeFirst()
    }

    func write(_ string: String) { inner.written.append(string) }
}
