import Testing
@testable import SpellbookKit

struct SwitchNavigatorTests {

    private let navigator = SwitchNavigator()

    // MARK: - No switches

    @Test func noSwitches_returnsSpellAndAllArgv() throws {
        let spell = SpellDefinition(name: "hello", script: "echo hi")
        let result = try navigator.resolve(
            spell: spell, argv: ["--flag", "val"], spellName: "hello"
        )
        #expect(result.terminal.script == "echo hi")
        #expect(result.remainingArgv == ["--flag", "val"])
    }

    // MARK: - Match by canonical name

    @Test func matchByCanonicalName_consumesArg() throws {
        let spell = switchSpell(options: [
            option("dev", script: "run dev"),
            option("prod", script: "run prod")
        ])
        let result = try navigator.resolve(
            spell: spell, argv: ["prod", "--verbose"], spellName: "deploy"
        )
        #expect(result.terminal.script == "run prod")
        #expect(result.remainingArgv == ["--verbose"])
    }

    // MARK: - Match by alias

    @Test func matchByAlias_consumesArg() throws {
        let spell = switchSpell(options: [
            option("development", aliases: ["dev", "d"], script: "run dev"),
            option("production", aliases: ["prod"], script: "run prod")
        ])
        let result = try navigator.resolve(
            spell: spell, argv: ["d"], spellName: "deploy"
        )
        #expect(result.terminal.script == "run dev")
        #expect(result.remainingArgv == [])
    }

    // MARK: - Default key

    @Test func noArg_defaultKey_usesDefault() throws {
        let spell = switchSpell(
            options: [
                option("dev", script: "run dev"),
                option("prod", script: "run prod")
            ],
            defaultBranch: .key("dev")
        )
        let result = try navigator.resolve(
            spell: spell, argv: [], spellName: "deploy"
        )
        #expect(result.terminal.script == "run dev")
        #expect(result.remainingArgv == [])
    }

    // MARK: - Inline default

    @Test func noArg_inlineDefault_usesInline() throws {
        let inline = SpellDefinition(name: "deploy", script: "run default")
        let spell = switchSpell(
            options: [option("dev", script: "run dev")],
            defaultBranch: .inline(inline)
        )
        let result = try navigator.resolve(
            spell: spell, argv: [], spellName: "deploy"
        )
        #expect(result.terminal.script == "run default")
    }

    // MARK: - No default, no arg

    @Test func noArg_noDefault_throws() {
        let spell = switchSpell(options: [
            option("dev", script: "run dev"),
            option("prod", script: "run prod")
        ])
        #expect(throws: SpellbookError.switchRequiresOption(spell: "deploy", available: ["dev", "prod"])) {
            try navigator.resolve(spell: spell, argv: [], spellName: "deploy")
        }
    }

    // MARK: - Unknown option, no default

    @Test func unknownArg_noDefault_throwsOptionNotFound() {
        let spell = switchSpell(options: [
            option("dev", script: "run dev"),
            option("prod", script: "run prod")
        ])
        #expect(throws: SpellbookError.switchOptionNotFound(
                    spell: "deploy", option: "staging", available: ["dev", "prod"]
                )) {
            try navigator.resolve(spell: spell, argv: ["staging"], spellName: "deploy")
        }
    }

    // MARK: - Unknown option with default falls back

    @Test func unknownArg_withDefault_usesDefault_keepsArgv() throws {
        let spell = switchSpell(
            options: [
                option("dev", script: "run dev"),
                option("prod", script: "run prod")
            ],
            defaultBranch: .key("dev")
        )
        let result = try navigator.resolve(
            spell: spell, argv: ["--verbose"], spellName: "deploy"
        )
        #expect(result.terminal.script == "run dev")
        #expect(result.remainingArgv == ["--verbose"])
    }

    // MARK: - Nested switches

    @Test func nestedSwitches_navigatesRecursively() throws {
        let innerSwitch = SwitchDefinition(options: [
            SwitchOptionDefinition(
                name: "ios",
                command: SpellDefinition(name: "ios", script: "build ios")
            ),
            SwitchOptionDefinition(
                name: "android",
                command: SpellDefinition(name: "android", script: "build android")
            )
        ])
        let outerOption = SpellDefinition(
            identity: SpellIdentity(name: "mobile"),
            body: SpellBody(switchBranches: innerSwitch)
        )
        let outerSwitch = SwitchDefinition(options: [
            SwitchOptionDefinition(name: "mobile", command: outerOption),
            SwitchOptionDefinition(
                name: "web",
                command: SpellDefinition(name: "web", script: "build web")
            )
        ])
        let spell = SpellDefinition(
            identity: SpellIdentity(name: "build"),
            body: SpellBody(switchBranches: outerSwitch)
        )

        let result = try navigator.resolve(
            spell: spell, argv: ["mobile", "ios", "--release"], spellName: "build"
        )
        #expect(result.terminal.script == "build ios")
        #expect(result.remainingArgv == ["--release"])
    }

    // MARK: - Helpers

    private func option(
        _ name: String,
        aliases: [String] = [],
        script: String
    ) -> SwitchOptionDefinition {
        SwitchOptionDefinition(
            name: name,
            aliases: aliases,
            command: SpellDefinition(name: name, script: script)
        )
    }

    private func switchSpell(
        options: [SwitchOptionDefinition],
        defaultBranch: DefaultBranch = .none
    ) -> SpellDefinition {
        SpellDefinition(
            identity: SpellIdentity(name: "deploy"),
            body: SpellBody(
                switchBranches: SwitchDefinition(
                    options: options, defaultBranch: defaultBranch
                )
            )
        )
    }
}
