import Testing
@testable import SpellbookKit

struct Phase3PickerHeadlessTests {

    @Test func stagingSelectedViaPicker() {
        let inner = MutableTTYSource(bytes: [0x0D])
        var source = ClassTTYSourceWrapper(inner: inner)
        let outcome = TTYPickerHarness.run(
            candidates: ["staging", "prod", "dev"], source: &source
        )
        #expect(outcome == .accepted(0))
    }

    @Test func fuzzyFilterThenEnter_selectsProd() {
        let inner = MutableTTYSource(bytes: [0x70, 0x0D])
        var source = ClassTTYSourceWrapper(inner: inner)
        let outcome = TTYPickerHarness.run(
            candidates: ["staging", "prod", "dev"], source: &source
        )
        if case .accepted(let idx) = outcome {
            #expect(["staging", "prod", "dev"][idx] == "prod")
        } else {
            #expect(Bool(false), "expected accepted")
        }
    }

    @Test func escOnEmptyQuery_cancelsAndRestoresTerminal() {
        let inner = MutableTTYSource(bytes: [0x1B])
        var source = ClassTTYSourceWrapper(inner: inner)
        let outcome = TTYPickerHarness.run(
            candidates: ["staging", "prod"], source: &source
        )
        #expect(outcome == .cancelled)
        #expect(inner.rawRestored)
    }
}
