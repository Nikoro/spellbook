import Testing
@testable import SpellbookKit

struct ActivationSummaryRendererTests {

    @Test func empty_producesNoLines() {
        #expect(ActivationSummaryRenderer.renderChanges([]).isEmpty)
    }

    @Test func preservesEntryOrderAndMarkers() {
        let lines = ActivationSummaryRenderer.renderChanges([
            DiffEntry(name: "deploy", kind: .added),
            DiffEntry(name: "test", kind: .changed),
            DiffEntry(name: "lint", kind: .removed)
        ])
        #expect(lines == ["  + deploy", "  ~ test", "  - lint"])
    }
}
