import Testing
@testable import SpellbookKit

struct ParamResolverPickerTests {

    // MARK: - Enum positional picker

    @Test func missingRequiredEnum_pickerSelects() throws {
        let provider = MockChoiceProvider()
        provider.outcome = .selected(1)
        let resolver = ParamResolver(choiceProvider: provider)
        let param = enumParam(name: "env", values: ["dev", "staging", "prod"])

        let result = try resolver.resolve(
            argv: [], params: [param], spell: "deploy", passthrough: false
        )

        #expect(result.values["env"] == "staging")
        #expect(provider.chosenOptions == ["dev", "staging", "prod"])
    }

    @Test func missingRequiredEnum_pickerCancelled() {
        let provider = MockChoiceProvider()
        provider.outcome = .cancelled
        let resolver = ParamResolver(choiceProvider: provider)
        let param = enumParam(name: "env", values: ["dev", "prod"])

        #expect(throws: SpellbookError.selectionCancelled(spell: "deploy")) {
            try resolver.resolve(
                argv: [], params: [param], spell: "deploy", passthrough: false
            )
        }
    }

    @Test func missingRequiredEnum_pickerUnavailable_throwsMissingWithValues() {
        let provider = MockChoiceProvider()
        provider.outcome = .unavailable
        let resolver = ParamResolver(choiceProvider: provider)
        let param = enumParam(name: "env", values: ["dev", "prod"])

        let error = #expect(throws: SpellbookError.self) {
            try resolver.resolve(
                argv: [], params: [param], spell: "deploy", passthrough: false
            )
        }
        #expect(
            error == .missingRequiredEnumValue(
                spell: "deploy", param: "env", values: ["dev", "prod"]
            )
        )
    }

    // MARK: - Enum named picker

    @Test func missingRequiredNamedEnum_pickerSelects() throws {
        let provider = MockChoiceProvider()
        provider.outcome = .selected(0)
        let resolver = ParamResolver(choiceProvider: provider)
        let param = namedEnumParam(
            name: "env", flags: ["--env"], values: ["dev", "prod"]
        )

        let result = try resolver.resolve(
            argv: [], params: [param], spell: "deploy", passthrough: false
        )

        #expect(result.values["env"] == "dev")
    }

    // MARK: - Bool never triggers picker

    @Test func missingRequiredBool_pickerNotCalled() {
        let provider = MockChoiceProvider()
        provider.outcome = .selected(0)
        let resolver = ParamResolver(choiceProvider: provider)
        let param = ParamDefinition(
            name: "verbose",
            shape: ParamShape(isRequired: true, isPositional: true),
            schema: ParamSchema(type: .bool)
        )

        #expect(throws: SpellbookError.missingRequiredParam(spell: "test", param: "verbose", flags: [])) {
            try resolver.resolve(
                argv: [], params: [param], spell: "test", passthrough: false
            )
        }
        #expect(provider.callCount == 0)
    }

    // MARK: - Free-text never triggers picker

    @Test func missingRequiredString_pickerNotCalled() {
        let provider = MockChoiceProvider()
        provider.outcome = .selected(0)
        let resolver = ParamResolver(choiceProvider: provider)
        let param = ParamDefinition(
            name: "name",
            shape: ParamShape(isRequired: true, isPositional: true),
            schema: ParamSchema(type: .string)
        )

        #expect(throws: SpellbookError.missingRequiredParam(spell: "greet", param: "name", flags: [])) {
            try resolver.resolve(
                argv: [], params: [param], spell: "greet", passthrough: false
            )
        }
        #expect(provider.callCount == 0)
    }

    @Test func missingRequiredInt_pickerNotCalled() {
        let provider = MockChoiceProvider()
        provider.outcome = .selected(0)
        let resolver = ParamResolver(choiceProvider: provider)
        let param = ParamDefinition(
            name: "count",
            shape: ParamShape(isRequired: true, isPositional: true),
            schema: ParamSchema(type: .int)
        )

        #expect(throws: SpellbookError.missingRequiredParam(spell: "repeat", param: "count", flags: [])) {
            try resolver.resolve(
                argv: [], params: [param], spell: "repeat", passthrough: false
            )
        }
        #expect(provider.callCount == 0)
    }

    // MARK: - Provided enum skips picker

    @Test func enumProvidedByArg_pickerNotCalled() throws {
        let provider = MockChoiceProvider()
        let resolver = ParamResolver(choiceProvider: provider)
        let param = enumParam(name: "env", values: ["dev", "prod"])

        let result = try resolver.resolve(
            argv: ["dev"], params: [param], spell: "deploy", passthrough: false
        )

        #expect(result.values["env"] == "dev")
        #expect(provider.callCount == 0)
    }

    // MARK: - Helpers

    private func enumParam(
        name: String,
        values: [String]
    ) -> ParamDefinition {
        ParamDefinition(
            name: name,
            shape: ParamShape(isRequired: true, isPositional: true),
            schema: ParamSchema(type: .string, values: values)
        )
    }

    private func namedEnumParam(
        name: String,
        flags: [String],
        values: [String]
    ) -> ParamDefinition {
        ParamDefinition(
            name: name,
            shape: ParamShape(
                isRequired: true, isPositional: false, flags: flags
            ),
            schema: ParamSchema(type: .string, values: values)
        )
    }
}
