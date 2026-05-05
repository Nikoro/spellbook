import Testing
@testable import SpellbookKit

struct ParamResolverTypeValidationTests {
    private let resolver = ParamResolver()

    @Test func namedScalarParam_invalidValue_throwsStructuredError() {
        let count = ParamDefinition(
            name: "count",
            shape: ParamShape(isRequired: true, isPositional: false, flags: ["--count"]),
            schema: ParamSchema(type: .int)
        )

        #expect(throws: SpellbookError.invalidParamValue(
                    spell: "deploy",
                    param: "count",
                    value: "oops",
                    expected: .int,
                    validValues: [],
                    example: "42"
                )) {
            try resolve(argv: ["--count", "oops"], params: [count])
        }
    }

    @Test func positionalScalarParam_invalidValue_throwsStructuredError() {
        let dryRun = ParamDefinition(
            name: "dry_run",
            shape: ParamShape(isRequired: true, isPositional: true),
            schema: ParamSchema(type: .bool)
        )

        #expect(throws: SpellbookError.invalidParamValue(
                    spell: "deploy",
                    param: "dry_run",
                    value: "yes",
                    expected: .bool,
                    validValues: [],
                    example: "true"
                )) {
            try resolve(argv: ["yes"], params: [dryRun])
        }
    }

    @Test func defaultValue_isValidated_throughIntegratedResolverPath() {
        let threshold = ParamDefinition(
            name: "threshold",
            shape: ParamShape(isRequired: false, isPositional: true),
            schema: ParamSchema(type: .double, defaultValue: "oops")
        )

        #expect(throws: SpellbookError.invalidParamValue(
                    spell: "deploy",
                    param: "threshold",
                    value: "oops",
                    expected: .double,
                    validValues: [],
                    example: "3.14"
                )) {
            try resolve(argv: [], params: [threshold])
        }
    }

    @Test func boolFlag_resolvedValue_isValidated_andPreserved() throws {
        let verbose = ParamDefinition(
            name: "verbose",
            shape: ParamShape(isRequired: false, isPositional: false, flags: ["--verbose"]),
            schema: ParamSchema(type: .bool)
        )

        let result = try resolve(argv: ["--verbose", "true"], params: [verbose])

        #expect(result.values == ["verbose": "true"])
    }

    @Test func enumValue_isCanonicalized_throughIntegratedResolverPath() throws {
        let env = ParamDefinition(
            name: "env",
            shape: ParamShape(isRequired: true, isPositional: false, flags: ["--env"]),
            schema: ParamSchema(type: .string, values: ["dev", "Prod"])
        )

        let result = try resolve(argv: ["--env", "prod"], params: [env])

        #expect(result.values == ["env": "Prod"])
    }

    private func resolve(
        argv: [String],
        params: [ParamDefinition],
        passthrough: Bool = false
    ) throws -> ParsedArguments {
        try resolver.resolve(
            argv: argv,
            params: params,
            spell: "deploy",
            passthrough: passthrough
        )
    }
}
