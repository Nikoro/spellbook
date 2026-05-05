enum TTYInputDecoder {
    static func decode(
        byte: UInt8,
        readNext: () -> UInt8?
    ) -> FuzzyPickerInput? {
        switch byte {
        case 0x0D, 0x0A: return .confirm
        case 0x7F, 0x08: return .backspace
        case 0x1B: return decodeEscape(readNext: readNext)
        case 0x31...0x39: return .digit(Int(byte) - 0x30)
        case 0x20...0x7E:
            let scalar = Unicode.Scalar(byte)
            return .char(Character(scalar))
        default: return nil
        }
    }

    private static func decodeEscape(
        readNext: () -> UInt8?
    ) -> FuzzyPickerInput? {
        guard let next = readNext() else { return .cancel }
        guard next == 0x5B else { return .cancel }
        guard let arrow = readNext() else { return .cancel }
        switch arrow {
        case 0x41: return .moveUp
        case 0x42: return .moveDown
        default: return nil
        }
    }
}
