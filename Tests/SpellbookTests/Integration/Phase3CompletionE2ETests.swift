import Testing
@testable import SpellbookKit

private typealias Fix = Phase3E2EFixtures

struct Phase3CompletionE2ETests {

    @Test func sbdeployTabOpensRequiredSlot() {
        let values = Fix.candidateValues(
            wrapper: "sbdeploy", tokens: ["sbdeploy", ""], cword: 1
        )
        #expect(values == ["staging", "prod", "dev"])
    }

    @Test func sbdeployStTab_fuzzyFiltersToStaging() {
        let values = Fix.candidateValues(
            wrapper: "sbdeploy", tokens: ["sbdeploy", "st"], cword: 1
        )
        #expect(values.first == "staging")
    }

    @Test func sbtestEnvSpaceTab_offersEnumValues() {
        let values = Fix.candidateValues(
            wrapper: "sbtest", tokens: ["sbtest", "--env", ""], cword: 2
        )
        #expect(values == ["staging", "prod"])
    }

    @Test func helloTab_noSpaceNoSlot_fallthrough() {
        let values = Fix.candidateValues(
            wrapper: "hello", tokens: ["hello"], cword: 0
        )
        #expect(values == ["__SPELLBOOK_FALLTHROUGH__"])
    }

    @Test func helloSpaceTab_showsRunAsIs() {
        let lines = Fix.lines(wrapper: "hello", tokens: ["hello", ""], cword: 1)
        #expect(lines.contains(where: {
            let parts = $0.split(separator: "\t", omittingEmptySubsequences: false)
            return parts.count >= 2 && parts[1] == "runAsIs"
        }))
    }

    @Test func unknownWrapper_emitsEmptyBell() {
        let lines = Fix.lines(wrapper: "nope", tokens: ["nope"], cword: 0)
        #expect(lines.isEmpty)
    }
}
