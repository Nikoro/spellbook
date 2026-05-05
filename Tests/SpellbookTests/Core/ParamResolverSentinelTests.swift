import Testing
@testable import SpellbookKit

struct ParamResolverSentinelTests {
    private let resolver = ParamResolver()

    @Test func sentinel_beforeParams_routesRemainingTokensToPassthrough() throws {
        let params = [
            ParamDefinition(
                name: "env",
                shape: ParamShape(isRequired: false, isPositional: false, flags: ["--env"])
            )
        ]

        let result = try resolve(
            argv: ["--", "--env", "prod"],
            params: params,
            passthrough: true
        )

        #expect(result.values == [:])
        #expect(result.passthrough == ["--env", "prod"])
    }

    @Test func sentinel_afterParams_keepsEarlierValues_andExcludesSentinel() throws {
        let params = [ParamDefinition(name: "env", isRequired: true, isPositional: true)]

        let result = try resolve(
            argv: ["prod", "--", "--watch", "-v"],
            params: params,
            passthrough: true
        )

        #expect(result.values == ["env": "prod"])
        #expect(result.passthrough == ["--watch", "-v"])
    }

    @Test func sentinel_withoutFollowingTokens_isIgnored() throws {
        let result = try resolve(argv: ["--"], params: [], passthrough: true)

        #expect(result.values == [:])
        #expect(result.passthrough == [])
    }

    @Test func sentinel_withoutPassthrough_throwsUnexpectedArgumentForFirstTrailingToken() {
        let params = [ParamDefinition(name: "env", isRequired: true, isPositional: true)]

        #expect(throws: SpellbookError.unexpectedArgument(
                    spell: "deploy",
                    value: "--watch",
                    index: 2,
                    origin: .afterStopParsingSentinel
                )) {
            try resolve(argv: ["prod", "--", "--watch", "-v"], params: params)
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
