@testable import SpellbookKit

final class MutableTTYSource {
    var queue: [UInt8]
    var rawEntered = false
    var rawRestored = false
    var written: [String] = []
    var isTTY: Bool

    init(bytes: [UInt8], isTTY: Bool = true) {
        self.queue = bytes
        self.isTTY = isTTY
    }
}
