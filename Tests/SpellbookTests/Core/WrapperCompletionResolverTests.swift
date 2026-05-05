import Testing
@testable import SpellbookKit

private typealias Fix = WrapperCompletionTestFixtures

struct WrapperCompletionResolverTests {

    // MARK: FR-40 — trigger rules

    @Test func completeCommand_noTrailingSpace_returnsFallthrough() {
        let book = Fix.manifest([Fix.spell("hello")])
        let out = Fix.resolve(book, wrapper: "hello", tokens: ["hello"], cword: 0)
        #expect(out == [.endOfGrammarFallThrough])
    }

    @Test func completeCommand_withSpace_sectionedRunAsIs() {
        let book = Fix.manifest([Fix.spell("hello")])
        let out = Fix.resolve(book, wrapper: "hello", tokens: ["hello", ""], cword: 1)
        #expect(out.contains(where: { $0.kind == .runAsIs }))
    }

    @Test func requiredNextSlot_emitsSlotCandidates_notRunAsIs() {
        let param = Fix.requiredEnumParam(name: "env", values: ["staging", "prod"])
        let book = Fix.manifest([Fix.spell("sbdeploy", params: [param])])
        let out = Fix.resolve(book, wrapper: "sbdeploy", tokens: ["sbdeploy"], cword: 0)
        #expect(out.map(\.value) == ["staging", "prod"])
        #expect(!out.contains(where: { $0.kind == .runAsIs }))
    }

    @Test func dashDashTrigger_opensFlagOnlyPicker() {
        let flag = Fix.optionalFlagBool(name: "v", flags: ["--verbose", "-v"])
        let pos = ParamDefinition(
            name: "target",
            shape: ParamShape(isRequired: false, isPositional: true)
        )
        let book = Fix.manifest([Fix.spell("x", params: [pos, flag])])
        let out = Fix.resolve(book, wrapper: "x", tokens: ["x", "--"], cword: 1)
        #expect(out.allSatisfy { $0.kind == .namedFlag })
        #expect(out.map(\.value) == ["--verbose"])
    }

    @Test func singleDashTrigger_opensFlagOnlyPicker() {
        let flag = Fix.optionalFlagBool(name: "v", flags: ["--verbose", "-v"])
        let book = Fix.manifest([Fix.spell("x", params: [flag])])
        let out = Fix.resolve(book, wrapper: "x", tokens: ["x", "-"], cword: 1)
        #expect(out.allSatisfy { $0.kind == .namedFlag })
    }

    @Test func partialToken_returnsFullCandidateSet_notPrefiltered() {
        let param = Fix.requiredEnumParam(name: "env", values: ["staging", "prod", "dev"])
        let book = Fix.manifest([Fix.spell("x", params: [param])])
        let out = Fix.resolve(book, wrapper: "x", tokens: ["x", "st"], cword: 1)
        #expect(out.map(\.value) == ["staging", "prod", "dev"])
    }

    // MARK: FR-41 — required-first

    @Test func requiredPositionalUnsatisfied_hidesOptionalCandidates() {
        let required = Fix.requiredEnumParam(name: "env", values: ["staging", "prod"])
        let optFlag = Fix.optionalFlagBool(name: "v", flags: ["--verbose"])
        let book = Fix.manifest([Fix.spell("x", params: [required, optFlag])])
        let out = Fix.resolve(book, wrapper: "x", tokens: ["x", ""], cword: 1)
        #expect(out.map(\.value) == ["staging", "prod"])
        #expect(!out.contains(where: { $0.value == "--verbose" }))
    }

    @Test func allRequiredSatisfied_emitsSectionedCandidates() {
        let required = Fix.requiredEnumParam(name: "env", values: ["staging", "prod"])
        let optFlag = Fix.optionalFlagBool(name: "v", flags: ["--verbose"])
        let book = Fix.manifest([Fix.spell("x", params: [required, optFlag])])
        let out = Fix.resolve(book, wrapper: "x", tokens: ["x", "staging", ""], cword: 2)
        let flags = out.filter { $0.kind == .namedFlag }.map(\.value)
        #expect(flags == ["--verbose"])
        #expect(out.contains(where: { $0.kind == .runAsIs }))
    }

    @Test func mergedManifestUsed_noProvenanceLeaks() {
        let param = Fix.requiredEnumParam(name: "env", values: ["prod"])
        let book = Fix.manifest([Fix.spell("x", params: [param])])
        let out = Fix.resolve(book, wrapper: "x", tokens: ["x"], cword: 0)
        #expect(out.map(\.value) == ["prod"])
    }
}
