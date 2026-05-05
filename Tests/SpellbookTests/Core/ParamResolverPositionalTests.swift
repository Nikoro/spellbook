import Testing
@testable import SpellbookKit

struct ParamResolverPositionalTests {
    private let resolver = ParamResolver()

    @Test func emptyArgv_emptyParams_yieldsEmptyResult() throws {
        let result = try resolve(argv: [], params: [])
        #expect(result.values == [:])
        #expect(result.passthrough == [])
    }

    @Test func singleRequiredPositional_consumesFirstToken() throws {
        let env = ParamDefinition(name: "env", isRequired: true, isPositional: true)
        let result = try resolve(argv: ["prod"], params: [env])
        #expect(result.values == ["env": "prod"])
    }

    @Test func twoPositionals_consumeInOrder() throws {
        let params = [
            ParamDefinition(name: "env", isRequired: true, isPositional: true),
            ParamDefinition(name: "region", isRequired: true, isPositional: true)
        ]
        let result = try resolve(argv: ["prod", "eu"], params: params)
        #expect(result.values == ["env": "prod", "region": "eu"])
    }

    @Test func missingRequiredPositional_throws() {
        let params = [ParamDefinition(name: "env", isRequired: true, isPositional: true)]
        #expect(throws: SpellbookError.missingRequiredParam(
                    spell: "deploy",
                    param: "env",
                    flags: []
                )) {
            try resolve(argv: [], params: params)
        }
    }

    @Test func optionalPositional_missing_usesDefault() throws {
        let params = [
            ParamDefinition(
                name: "env",
                shape: ParamShape(isRequired: false, isPositional: true),
                schema: ParamSchema(defaultValue: "dev")
            )
        ]
        let result = try resolve(argv: [], params: params)
        #expect(result.values == ["env": "dev"])
    }

    @Test func extraPositional_withoutPassthrough_throws() {
        let params = [ParamDefinition(name: "env", isRequired: true, isPositional: true)]
        #expect(throws: SpellbookError.unexpectedArgument(
                    spell: "deploy",
                    value: "junk",
                    index: 1,
                    origin: .regular
                )) {
            try resolve(argv: ["prod", "junk"], params: params)
        }
    }

    @Test func extraPositional_withPassthrough_goesToPassthrough() throws {
        let params = [ParamDefinition(name: "env", isRequired: true, isPositional: true)]
        let result = try resolve(
            argv: ["prod", "--watch", "-v"],
            params: params,
            passthrough: true
        )
        #expect(result.values == ["env": "prod"])
        #expect(result.passthrough == ["--watch", "-v"])
    }

    private func resolve(
        argv: [String],
        params: [ParamDefinition],
        passthrough: Bool = false
    ) throws -> ParsedArguments {
        try resolver.resolve(argv: argv, params: params, spell: "deploy", passthrough: passthrough)
    }
}
