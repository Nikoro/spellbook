import Testing
@testable import SpellbookKit

private typealias Fix = WrapperCompletionTestFixtures

struct WrapperCompletionGrammarTests {

    // MARK: switch (flat / nested)

    @Test func flatSwitch_emitsOptionNames() {
        let optA = SwitchOptionDefinition(name: "build", command: Fix.spell("build"))
        let optB = SwitchOptionDefinition(name: "deploy", command: Fix.spell("deploy"))
        let switchDef = SwitchDefinition(options: [optA, optB])
        let root = Fix.spell("sb", switchBranches: switchDef, script: nil)
        let book = Fix.manifest([root])
        let out = Fix.resolve(book, wrapper: "sb", tokens: ["sb"], cword: 0)
        #expect(out.map(\.value) == ["build", "deploy"])
        #expect(out.allSatisfy { $0.kind == .switchOption })
    }

    @Test func nestedSwitch_descendsIntoChosenBranch() {
        let innerA = SwitchOptionDefinition(name: "staging", command: Fix.spell("stg"))
        let innerB = SwitchOptionDefinition(name: "prod", command: Fix.spell("prd"))
        let innerSwitch = SwitchDefinition(options: [innerA, innerB])
        let deploy = Fix.spell("deploy", switchBranches: innerSwitch, script: nil)
        let deployOpt = SwitchOptionDefinition(name: "deploy", command: deploy)
        let root = Fix.spell(
            "sb", switchBranches: SwitchDefinition(options: [deployOpt]), script: nil
        )
        let book = Fix.manifest([root])
        let out = Fix.resolve(book, wrapper: "sb", tokens: ["sb", "deploy", ""], cword: 2)
        #expect(out.map(\.value) == ["staging", "prod"])
    }

    // MARK: bool / enum / string / named flag with value

    @Test func boolPositional_offersTrueFalse() {
        let param = ParamDefinition(
            name: "force",
            shape: ParamShape(isRequired: true, isPositional: true),
            schema: ParamSchema(type: .bool)
        )
        let book = Fix.manifest([Fix.spell("x", params: [param])])
        let out = Fix.resolve(book, wrapper: "x", tokens: ["x"], cword: 0)
        #expect(out.map(\.value) == ["true", "false"])
    }

    @Test func stringPositional_noEnum_fallsThroughToShell() {
        let param = ParamDefinition(
            name: "file",
            shape: ParamShape(isRequired: true, isPositional: true),
            schema: ParamSchema(type: .string)
        )
        let book = Fix.manifest([Fix.spell("x", params: [param])])
        let out = Fix.resolve(book, wrapper: "x", tokens: ["x"], cword: 0)
        #expect(out == [.endOfGrammarFallThrough])
    }

    @Test func namedFlagWithValue_afterFlag_offersEnumValues() {
        let flag = Fix.flagWithEnumValue(
            name: "env", flags: ["--env"], values: ["staging", "prod"]
        )
        let book = Fix.manifest([Fix.spell("x", params: [flag])])
        let out = Fix.resolve(book, wrapper: "x", tokens: ["x", "--env", ""], cword: 2)
        #expect(out.map(\.value) == ["staging", "prod"])
    }

    @Test func namedFlagWithValue_carriesNeedsValueMarker() {
        let flag = Fix.flagWithEnumValue(
            name: "env", flags: ["--env"], values: ["staging", "prod"]
        )
        let book = Fix.manifest([Fix.spell("x", params: [flag])])
        let out = Fix.resolve(book, wrapper: "x", tokens: ["x", "--"], cword: 1)
        let envCand = out.first { $0.value == "--env" }
        #expect(envCand?.needsValueNext == true)
    }

    @Test func boolNamedFlag_doesNotCarryNeedsValueMarker() {
        let flag = Fix.optionalFlagBool(name: "v", flags: ["--verbose"])
        let book = Fix.manifest([Fix.spell("x", params: [flag])])
        let out = Fix.resolve(book, wrapper: "x", tokens: ["x", "--"], cword: 1)
        let verbose = out.first { $0.value == "--verbose" }
        #expect(verbose?.needsValueNext == false)
    }

    // MARK: FR-51

    @Test func unknownWrapper_emitsEmptyBell() {
        let book = Fix.manifest([Fix.spell("hello")])
        let out = Fix.resolve(book, wrapper: "unknown", tokens: ["unknown"], cword: 0)
        #expect(out.isEmpty)
    }

    @Test func unknownFlagMidGrammar_emitsEmptyBell() {
        let param = ParamDefinition(
            name: "env",
            shape: ParamShape(isRequired: false, isPositional: true),
            schema: ParamSchema(type: .string, values: ["staging"])
        )
        let book = Fix.manifest([Fix.spell("x", params: [param])])
        let out = Fix.resolve(book, wrapper: "x", tokens: ["x", "--bogus", ""], cword: 2)
        #expect(out.isEmpty)
    }

    @Test func duplicateFlag_emitsEmptyBell() {
        let flag = Fix.flagWithEnumValue(
            name: "env", flags: ["--env"], values: ["staging", "prod"]
        )
        let book = Fix.manifest([Fix.spell("x", params: [flag])])
        let out = Fix.resolve(book, wrapper: "x",
                              tokens: ["x", "--env", "staging", "--env", ""], cword: 4)
        #expect(out.isEmpty)
    }

    @Test func invalidEnumEarlierSlot_emitsEmptyBell() {
        let envParam = Fix.requiredEnumParam(name: "env", values: ["staging", "prod"])
        let colorParam = ParamDefinition(
            name: "color",
            shape: ParamShape(isRequired: false, isPositional: true),
            schema: ParamSchema(type: .string, values: ["red", "blue"])
        )
        let book = Fix.manifest([Fix.spell("x", params: [envParam, colorParam])])
        let out = Fix.resolve(book, wrapper: "x", tokens: ["x", "bogus", ""], cword: 2)
        #expect(out.isEmpty)
    }

    @Test func allGrammarSatisfied_noPassthrough_showsRunAsIs() {
        let param = Fix.requiredEnumParam(name: "env", values: ["staging"])
        let book = Fix.manifest([Fix.spell("x", params: [param], script: "deploy {{env}}")])
        let out = Fix.resolve(book, wrapper: "x", tokens: ["x", "staging", ""], cword: 2)
        #expect(out.contains(where: { $0.kind == .runAsIs }))
    }

    @Test func allGrammarSatisfied_withPassthrough_fallsThrough() {
        let param = Fix.requiredEnumParam(name: "env", values: ["staging"])
        let book = Fix.manifest([Fix.spell("x", params: [param], script: "deploy {{env}} ...args")])
        let out = Fix.resolve(book, wrapper: "x",
                              tokens: ["x", "staging", "anything", ""], cword: 3)
        #expect(out == [.endOfGrammarFallThrough])
    }
}
