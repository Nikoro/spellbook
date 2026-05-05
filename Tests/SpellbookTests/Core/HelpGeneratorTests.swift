import Testing
@testable import SpellbookKit

struct HelpGeneratorTests {

    @Test func simpleSpell_showsNameAndDescription() {
        let spell = SpellDefinition(name: "build", description: "Build the project", script: "make")
        let help = HelpGenerator.spellHelp(spell)
        #expect(help.hasPrefix("build — Build the project"))
    }

    @Test func spellWithoutDescription_showsNameOnly() {
        let spell = SpellDefinition(name: "build", script: "make")
        let help = HelpGenerator.spellHelp(spell)
        #expect(help == "build")
    }

    @Test func spellWithAliases_showsAliases() {
        let spell = SpellDefinition(
            identity: SpellIdentity(name: "test", aliases: ["t", "tst"]),
            body: SpellBody(script: "swift test")
        )
        let help = HelpGenerator.spellHelp(spell)
        #expect(help.contains("Aliases: t, tst"))
    }

    @Test func spellWithParams_showsParamTable() {
        let spell = SpellDefinition(
            identity: SpellIdentity(name: "deploy", description: "Deploy app"),
            body: SpellBody(
                script: "deploy {{env}}",
                params: [
                    ParamDefinition(name: "env", isRequired: true, isPositional: true)
                ]
            )
        )
        let help = HelpGenerator.spellHelp(spell)
        #expect(help.contains("Parameters:"))
        #expect(help.contains("<env>"))
        #expect(help.contains("(required)"))
    }

    @Test func paramWithFlags_showsFlags() {
        let spell = SpellDefinition(
            identity: SpellIdentity(name: "greet"),
            body: SpellBody(
                script: "echo {{name}}",
                params: [
                    ParamDefinition(
                        name: "name",
                        shape: ParamShape(
                            isRequired: false,
                            isPositional: false,
                            flags: ["--name", "-n"]
                        ),
                        schema: ParamSchema(defaultValue: "World")
                    )
                ]
            )
        )
        let help = HelpGenerator.spellHelp(spell)
        #expect(help.contains("--name, -n"))
        #expect(help.contains("(default: World)"))
    }

    @Test func spellWithSwitch_showsCommands() {
        let spell = SpellDefinition(
            identity: SpellIdentity(name: "deploy"),
            body: SpellBody(switchBranches: SwitchDefinition(
                options: [
                    SwitchOptionDefinition(
                        name: "staging",
                        aliases: ["stg"],
                        description: "Deploy to staging",
                        command: SpellDefinition(name: "staging", script: "deploy stg")
                    ),
                    SwitchOptionDefinition(
                        name: "production",
                        command: SpellDefinition(name: "production", script: "deploy prod")
                    )
                ],
                defaultBranch: .key("staging")
            ))
        )
        let help = HelpGenerator.spellHelp(spell)
        #expect(help.contains("Commands:"))
        #expect(help.contains("staging (stg)"))
        #expect(help.contains("Deploy to staging"))
        #expect(help.contains("production"))
        #expect(help.contains("Default: staging"))
    }

    @Test func aliasHelp_showsAliasContext() {
        let spell = SpellDefinition(name: "test", description: "Run tests", script: "swift test")
        let help = HelpGenerator.aliasHelp(name: "t", canonical: spell)
        #expect(help.hasPrefix("t is an alias for test"))
        #expect(help.contains("test — Run tests"))
    }
}
