import Testing
@testable import SpellbookKit

struct DoctorFixerTests {

    @Test func newSpellsWarning_triggersReactivate() {
        let report = DoctorReport(items: [warning("New spells not yet activated: sbfoo")])
        let assessment = DoctorFixer.assess(report: report)
        #expect(assessment.shouldReactivate)
        #expect(assessment.reasons == ["New spells not yet activated: sbfoo"])
    }

    @Test func staleWrappersWarning_triggersReactivate() {
        let report = DoctorReport(items: [warning("Stale wrappers for removed spells: sbbar")])
        #expect(DoctorFixer.assess(report: report).shouldReactivate)
    }

    @Test func projectNotActivated_triggersReactivate() {
        let report = DoctorReport(items: [warning("Project not yet activated. Run `spells` to activate")])
        #expect(DoctorFixer.assess(report: report).shouldReactivate)
    }

    @Test func pathWarning_doesNotTriggerReactivate() {
        let report = DoctorReport(items: [
            DiagnosticItem(severity: .warning, category: .path, message: "PATH missing")
        ])
        #expect(DoctorFixer.assess(report: report).shouldReactivate == false)
    }

    @Test func onlyInfoItems_doNotTrigger() {
        let report = DoctorReport(items: [
            DiagnosticItem(severity: .info, category: .wrappers, message: "Wrappers: up to date")
        ])
        #expect(DoctorFixer.assess(report: report).shouldReactivate == false)
    }

    private func warning(_ message: String) -> DiagnosticItem {
        DiagnosticItem(severity: .warning, category: .wrappers, message: message)
    }
}
