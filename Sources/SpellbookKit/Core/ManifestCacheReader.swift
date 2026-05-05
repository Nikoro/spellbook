import Foundation

struct ManifestCacheReader {
    let data: Data
    var cursor: Int = 0

    init(data: Data) { self.data = data }

    var isAtEnd: Bool { cursor == data.count }

    mutating func readMagic() -> Bool {
        guard cursor + 4 <= data.count else { return false }
        for (index, expected) in ManifestCacheCodec.magic.enumerated()
        where data[data.startIndex + cursor + index] != expected {
            return false
        }
        cursor += 4
        return true
    }

    mutating func readU8() -> UInt8? {
        guard cursor < data.count else { return nil }
        let value = data[data.startIndex + cursor]
        cursor += 1
        return value
    }

    mutating func readU16() -> UInt16? {
        guard let high = readU8(), let low = readU8() else { return nil }
        return (UInt16(high) << 8) | UInt16(low)
    }

    mutating func readU32() -> UInt32? {
        guard let byte0 = readU8(), let byte1 = readU8(),
              let byte2 = readU8(), let byte3 = readU8() else { return nil }
        return (UInt32(byte0) << 24) | (UInt32(byte1) << 16)
            | (UInt32(byte2) << 8) | UInt32(byte3)
    }

    mutating func readBool() -> Bool? {
        readU8().map { $0 != 0 }
    }

    mutating func readString() -> String? {
        guard let length = readU32() else { return nil }
        let end = cursor + Int(length)
        guard end <= data.count else { return nil }
        let slice = data[(data.startIndex + cursor)..<(data.startIndex + end)]
        cursor = end
        return String(data: slice, encoding: .utf8)
    }

    mutating func readOptionalString() -> (present: Bool, value: String?)? {
        guard let flag = readBool() else { return nil }
        if !flag { return (true, nil) }
        guard let str = readString() else { return nil }
        return (true, str)
    }

    mutating func readStringList() -> [String]? {
        guard let count = readU16() else { return nil }
        var out: [String] = []
        out.reserveCapacity(Int(count))
        for _ in 0..<Int(count) {
            guard let str = readString() else { return nil }
            out.append(str)
        }
        return out
    }
}
