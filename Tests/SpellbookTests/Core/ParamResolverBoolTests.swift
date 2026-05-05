import Testing
@testable import SpellbookKit

struct ParamResolverBoolTests {
    private let resolver = ParamResolver()

    // MARK: - Named Bool Flag Toggle

    @Test func boolFlag_noFollowingToken_togglesToTrue() throws {
        let verbose = boolFlag(name: "verbose", flags: ["--verbose"])
        let result = try resolve(argv: ["--verbose"], params: [verbose])
        #expect(result.values == ["verbose": "true"])
    }

    @Test func boolFlag_defaultTrue_togglesToFalse() throws {
        let verbose = boolFlag(
            name: "verbose", flags: ["--verbose"], defaultValue: "true"
        )
        let result = try resolve(argv: ["--verbose"], params: [verbose])
        #expect(result.values == ["verbose": "false"])
    }

    @Test func boolFlag_defaultFalse_togglesToTrue() throws {
        let verbose = boolFlag(
            name: "verbose", flags: ["--verbose"], defaultValue: "false"
        )
        let result = try resolve(argv: ["--verbose"], params: [verbose])
        #expect(result.values == ["verbose": "true"])
    }

    // MARK: - Named Bool Flag Explicit Value

    @Test func boolFlag_followedByTrue_consumesExplicitTrue() throws {
        let verbose = boolFlag(name: "verbose", flags: ["--verbose"])
        let result = try resolve(argv: ["--verbose", "true"], params: [verbose])
        #expect(result.values == ["verbose": "true"])
    }

    @Test func boolFlag_followedByFalse_consumesExplicitFalse() throws {
        let verbose = boolFlag(name: "verbose", flags: ["--verbose"])
        let result = try resolve(
            argv: ["--verbose", "false"], params: [verbose]
        )
        #expect(result.values == ["verbose": "false"])
    }

    // MARK: - Bool Flag Followed By Non-Bool Token

    @Test func boolFlag_followedByNonBool_toggles_tokenIsPositional() throws {
        let params = [
            boolFlag(name: "verbose", flags: ["--verbose"]),
            ParamDefinition(name: "env", isRequired: true, isPositional: true)
        ]
        let result = try resolve(argv: ["--verbose", "prod"], params: params)
        #expect(result.values["verbose"] == "true")
        #expect(result.values["env"] == "prod")
    }

    @Test func boolFlag_followedByNonBool_noPositional_passthrough() throws {
        let verbose = boolFlag(name: "verbose", flags: ["--verbose"])
        let result = try resolve(
            argv: ["--verbose", "prod"], params: [verbose], passthrough: true
        )
        #expect(result.values["verbose"] == "true")
        #expect(result.passthrough == ["prod"])
    }

    // MARK: - Bool Flag Short Form

    @Test func boolFlag_shortFlag_togglesToTrue() throws {
        let verbose = boolFlag(name: "verbose", flags: ["-v", "--verbose"])
        let result = try resolve(argv: ["-v"], params: [verbose])
        #expect(result.values == ["verbose": "true"])
    }

    // MARK: - Positional Bool

    @Test func positionalBool_consumesTrue() throws {
        let dryRun = ParamDefinition(
            name: "dry_run",
            shape: ParamShape(isRequired: true, isPositional: true),
            schema: ParamSchema(type: .bool)
        )
        let result = try resolve(argv: ["true"], params: [dryRun])
        #expect(result.values == ["dry_run": "true"])
    }

    @Test func positionalBool_consumesFalse() throws {
        let dryRun = ParamDefinition(
            name: "dry_run",
            shape: ParamShape(isRequired: true, isPositional: true),
            schema: ParamSchema(type: .bool)
        )
        let result = try resolve(argv: ["false"], params: [dryRun])
        #expect(result.values == ["dry_run": "false"])
    }

    @Test func optionalPositionalBool_missing_usesDefault() throws {
        let dryRun = ParamDefinition(
            name: "dry_run",
            shape: ParamShape(isRequired: false, isPositional: true),
            schema: ParamSchema(type: .bool, defaultValue: "true")
        )
        let result = try resolve(argv: [], params: [dryRun])
        #expect(result.values == ["dry_run": "true"])
    }

    // MARK: - Helpers

    private func boolFlag(
        name: String,
        flags: [String],
        defaultValue: String? = nil
    ) -> ParamDefinition {
        ParamDefinition(
            name: name,
            shape: ParamShape(
                isRequired: false, isPositional: false, flags: flags
            ),
            schema: ParamSchema(type: .bool, defaultValue: defaultValue)
        )
    }

    private func resolve(
        argv: [String],
        params: [ParamDefinition],
        passthrough: Bool = false
    ) throws -> ParsedArguments {
        try resolver.resolve(
            argv: argv, params: params,
            spell: "deploy", passthrough: passthrough
        )
    }
}
