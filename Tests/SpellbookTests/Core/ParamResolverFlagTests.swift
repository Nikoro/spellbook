import Testing
@testable import SpellbookKit

struct ParamResolverFlagTests {
    private let resolver = ParamResolver()

    @Test func namedParam_viaFlag_consumesNextToken() throws {
        let env = ParamDefinition(
            name: "env",
            shape: ParamShape(isRequired: true, isPositional: false, flags: ["-e", "--env"])
        )
        let result = try resolve(argv: ["--env", "prod"], params: [env])
        #expect(result.values == ["env": "prod"])
    }

    @Test func namedParam_shortFlag_consumesNextToken() throws {
        let env = ParamDefinition(
            name: "env",
            shape: ParamShape(isRequired: true, isPositional: false, flags: ["-e", "--env"])
        )
        let result = try resolve(argv: ["-e", "prod"], params: [env])
        #expect(result.values == ["env": "prod"])
    }

    @Test func namedAndPositional_intermixed() throws {
        let params = [
            ParamDefinition(name: "name", isRequired: true, isPositional: true),
            ParamDefinition(
                name: "env",
                shape: ParamShape(isRequired: true, isPositional: false, flags: ["--env"])
            )
        ]
        let result = try resolve(argv: ["--env", "prod", "alice"], params: params)
        #expect(result.values == ["name": "alice", "env": "prod"])
    }

    @Test func missingRequiredNamed_throws() {
        let env = ParamDefinition(
            name: "env",
            shape: ParamShape(isRequired: true, isPositional: false, flags: ["--env"])
        )
        #expect(throws: SpellbookError.missingRequiredParam(
                    spell: "deploy",
                    param: "env",
                    flags: ["--env"]
                )) {
            try resolve(argv: [], params: [env])
        }
    }

    @Test func namedParam_missingValue_throws() {
        let env = ParamDefinition(
            name: "env",
            shape: ParamShape(isRequired: true, isPositional: false, flags: ["--env"])
        )
        #expect(throws: SpellbookError.flagMissingValue(
                    spell: "deploy",
                    param: "env",
                    flag: "--env"
                )) {
            try resolve(argv: ["--env"], params: [env])
        }
    }

    @Test func longFlagEqualsValue_form_isErrorWithSeparateTokenSuggestion() {
        let env = ParamDefinition(
            name: "env",
            shape: ParamShape(isRequired: true, isPositional: false, flags: ["env", "--env"])
        )
        #expect(throws: SpellbookError.unsupportedEqualsForm(
                    spell: "deploy",
                    param: "env",
                    flag: "--env",
                    value: "prod"
                )) {
            try resolve(argv: ["--env=prod"], params: [env])
        }
    }

    @Test func nameEqualsValue_form_isErrorWithSeparateTokenSuggestion() {
        let env = ParamDefinition(
            name: "env",
            shape: ParamShape(isRequired: true, isPositional: false, flags: ["env", "--env"])
        )
        #expect(throws: SpellbookError.unsupportedEqualsForm(
                    spell: "deploy",
                    param: "env",
                    flag: "env",
                    value: "prod"
                )) {
            try resolve(argv: ["env=prod"], params: [env])
        }
    }

    private func resolve(
        argv: [String],
        params: [ParamDefinition],
        passthrough: Bool = false
    ) throws -> ParsedArguments {
        try resolver.resolve(argv: argv, params: params, spell: "deploy", passthrough: passthrough)
    }
}
