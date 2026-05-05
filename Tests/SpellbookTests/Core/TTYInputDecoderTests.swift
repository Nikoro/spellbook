import Testing
@testable import SpellbookKit

struct TTYInputDecoderTests {

    private func decode(_ bytes: [UInt8]) -> FuzzyPickerInput? {
        var cursor = 1
        return TTYInputDecoder.decode(byte: bytes[0]) {
            defer { cursor += 1 }
            return cursor < bytes.count ? bytes[cursor] : nil
        }
    }

    @Test func enter_confirms() { #expect(decode([0x0D]) == .confirm) }
    @Test func newline_confirms() { #expect(decode([0x0A]) == .confirm) }

    @Test func backspace_ascii127() { #expect(decode([0x7F]) == .backspace) }
    @Test func backspace_ascii8() { #expect(decode([0x08]) == .backspace) }

    @Test func digits_areDigits() {
        #expect(decode([0x31]) == .digit(1))
        #expect(decode([0x39]) == .digit(9))
    }

    @Test func printableAsciiBecomesChar() {
        #expect(decode([0x61]) == .char("a"))
        #expect(decode([0x5A]) == .char("Z"))
        #expect(decode([0x2D]) == .char("-"))
    }

    @Test func arrowUp() {
        #expect(decode([0x1B, 0x5B, 0x41]) == .moveUp)
    }

    @Test func arrowDown() {
        #expect(decode([0x1B, 0x5B, 0x42]) == .moveDown)
    }

    @Test func escAlone_cancels() {
        #expect(decode([0x1B]) == .cancel)
    }

    @Test func unknownByteIgnored() {
        #expect(decode([0x01]) == nil)
    }
}
