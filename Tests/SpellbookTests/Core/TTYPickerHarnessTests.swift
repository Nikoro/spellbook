import Testing
@testable import SpellbookKit

struct TTYPickerHarnessTests {

    @Test func acceptsFirstCandidateWithEnter() {
        let inner = MutableTTYSource(bytes: [0x0D])
        var source = ClassTTYSourceWrapper(inner: inner)
        let outcome = TTYPickerHarness.run(
            candidates: ["alpha", "beta"], source: &source
        )
        #expect(outcome == .accepted(0))
        #expect(inner.rawEntered)
        #expect(inner.rawRestored)
    }

    @Test func escClosesImmediatelyWhenQueryEmpty() {
        let inner = MutableTTYSource(bytes: [0x1B])
        var source = ClassTTYSourceWrapper(inner: inner)
        let outcome = TTYPickerHarness.run(
            candidates: ["alpha", "beta"], source: &source
        )
        #expect(outcome == .cancelled)
        #expect(inner.rawRestored)
    }

    @Test func arrowDownThenConfirm_selectsSecond() {
        let inner = MutableTTYSource(bytes: [0x1B, 0x5B, 0x42, 0x0D])
        var source = ClassTTYSourceWrapper(inner: inner)
        let outcome = TTYPickerHarness.run(
            candidates: ["alpha", "beta"], source: &source
        )
        #expect(outcome == .accepted(1))
    }

    @Test func typeCharThenEnter_selectsTopMatch() {
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

    @Test func nonTTY_returnsCancelled_withoutEnteringRawMode() {
        let inner = MutableTTYSource(bytes: [], isTTY: false)
        var source = ClassTTYSourceWrapper(inner: inner)
        let outcome = TTYPickerHarness.run(
            candidates: ["alpha"], source: &source
        )
        #expect(outcome == .cancelled)
        #expect(!inner.rawEntered)
    }
}
