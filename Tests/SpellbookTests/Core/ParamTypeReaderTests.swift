import Testing
@testable import SpellbookKit

struct ParamTypeReaderTests {

    @Test func readsBoolAlias() {
        #expect(ParamTypeReader.read(.scalar("bool")) == .bool)
    }

    @Test func readsBooleanAlias() {
        #expect(ParamTypeReader.read(.scalar("boolean")) == .bool)
    }

    @Test func readsIntAlias() {
        #expect(ParamTypeReader.read(.scalar("int")) == .int)
    }

    @Test func readsIntegerAlias() {
        #expect(ParamTypeReader.read(.scalar("integer")) == .int)
    }

    @Test func readsDoubleAlias() {
        #expect(ParamTypeReader.read(.scalar("double")) == .double)
    }

    @Test func readsNumAlias() {
        #expect(ParamTypeReader.read(.scalar("num")) == .number)
    }

    @Test func readsNumberAlias() {
        #expect(ParamTypeReader.read(.scalar("number")) == .number)
    }

    @Test func unrecognizedScalarFallsBackToString() {
        #expect(ParamTypeReader.read(.scalar("widget")) == .string)
    }

    @Test func nonScalarNodeFallsBackToString() {
        #expect(ParamTypeReader.read(.null) == .string)
    }
}
