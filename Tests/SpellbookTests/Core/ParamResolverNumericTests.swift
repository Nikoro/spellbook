import Testing
@testable import SpellbookKit

struct ParamResolverNumericTests {
    private let resolver = ParamResolver()

    @Test func namedIntFlag_consumesNegativeIntegerValue() throws {
        let count = ParamDefinition(
            name: "count",
            shape: ParamShape(isRequired: true, isPositional: false, flags: ["--count"]),
            schema: ParamSchema(type: .int)
        )

        let result = try resolve(argv: ["--count", "-2"], params: [count])

        #expect(result.values == ["count": "-2"])
    }

    @Test func namedDoubleFlag_consumesNegativeDoubleValue() throws {
        let threshold = ParamDefinition(
            name: "threshold",
            shape: ParamShape(isRequired: true, isPositional: false, flags: ["--threshold"]),
            schema: ParamSchema(type: .double)
        )

        let result = try resolve(argv: ["--threshold", "-2.5"], params: [threshold])

        #expect(result.values == ["threshold": "-2.5"])
    }

    @Test func negativeNumericToken_prefersCurrentPositionalNumberOverMatchingFlag() throws {
        let params = [
            ParamDefinition(
                name: "offset",
                shape: ParamShape(isRequired: true, isPositional: true),
                schema: ParamSchema(type: .number)
            ),
            ParamDefinition(
                name: "other",
                shape: ParamShape(isRequired: false, isPositional: false, flags: ["-3.14"])
            )
        ]

        let result = try resolve(argv: ["-3.14"], params: params)

        #expect(result.values == ["offset": "-3.14"])
    }

    @Test func stringFlag_followedByAnotherFlag_stillThrowsMissingValue() {
        let params = [
            ParamDefinition(
                name: "name",
                shape: ParamShape(isRequired: true, isPositional: false, flags: ["--name"])
            ),
            ParamDefinition(
                name: "verbose",
                shape: ParamShape(isRequired: false, isPositional: false, flags: ["--verbose"]),
                schema: ParamSchema(type: .bool)
            )
        ]

        #expect(throws: SpellbookError.flagMissingValue(
                    spell: "deploy",
                    param: "name",
                    flag: "--name"
                )) {
            try resolve(argv: ["--name", "--verbose"], params: params)
        }
    }

    @Test func negativeDoubleToken_notConsumedForIntPositional_whenItMatchesFlag() {
        let params = [
            ParamDefinition(
                name: "count",
                shape: ParamShape(isRequired: true, isPositional: true),
                schema: ParamSchema(type: .int)
            ),
            ParamDefinition(
                name: "other",
                shape: ParamShape(isRequired: false, isPositional: false, flags: ["-2.5"])
            )
        ]

        #expect(throws: SpellbookError.flagMissingValue(
                    spell: "deploy",
                    param: "other",
                    flag: "-2.5"
                )) {
            try resolve(argv: ["-2.5"], params: params)
        }
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
