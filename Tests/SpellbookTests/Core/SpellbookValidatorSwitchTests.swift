import Testing
@testable import SpellbookKit

struct SpellbookValidatorSwitchTests {
    private let validator = SpellbookValidator()

    @Test func switchLeafWithoutScript_isError() {
        let spell = spellWithSwitch(options: [
            SwitchOptionDefinition(
                name: "staging",
                command: SpellDefinition(name: "staging")
            )
        ])

        #expect(validator.validate(manifest(spell)) == [.switchLeafMissingScript(spell: "deploy", path: "staging")])
    }

    @Test func switchLeafWithScript_isValid() {
        let spell = spellWithSwitch(options: [
            SwitchOptionDefinition(
                name: "staging",
                command: SpellDefinition(name: "staging", script: "./deploy staging")
            )
        ])

        #expect(validator.validate(manifest(spell)) == [])
    }

    @Test func switch_duplicateOptionName_isError() {
        let spell = spellWithSwitch(options: [
            SwitchOptionDefinition(
                name: "staging",
                command: SpellDefinition(name: "staging", script: "./first")
            ),
            SwitchOptionDefinition(
                name: "staging",
                command: SpellDefinition(name: "staging", script: "./second")
            )
        ])

        #expect(validator.validate(manifest(spell)) == [.switchDuplicateName(spell: "deploy", name: "staging")])
    }

    @Test func switch_aliasCollidesWithOptionName_isError() {
        let spell = spellWithSwitch(options: [
            SwitchOptionDefinition(
                name: "staging",
                command: SpellDefinition(name: "staging", script: "./stage")
            ),
            SwitchOptionDefinition(
                name: "production",
                aliases: ["staging"],
                command: SpellDefinition(name: "production", script: "./prod")
            )
        ])

        #expect(validator.validate(manifest(spell)) == [.switchDuplicateName(spell: "deploy", name: "staging")])
    }

    @Test func default_keyReferencesUnknownOption_isError() {
        let spell = spellWithSwitch(
            options: [
                SwitchOptionDefinition(
                    name: "staging",
                    command: SpellDefinition(name: "staging", script: "./stage")
                )
            ],
            defaultBranch: .key("production")
        )

        #expect(validator.validate(manifest(spell)) == [.defaultKeyNotFound(spell: "deploy", key: "production")])
    }

    @Test func default_keyReferencesAlias_isError() {
        let spell = spellWithSwitch(
            options: [
                SwitchOptionDefinition(
                    name: "production",
                    aliases: ["prod"],
                    command: SpellDefinition(name: "production", script: "./prod")
                )
            ],
            defaultBranch: .key("prod")
        )

        #expect(
            validator.validate(manifest(spell)) ==
            [.defaultKeyIsAlias(spell: "deploy", alias: "prod", canonical: "production")]
        )
    }

    @Test func default_keyReferencesExistingCanonical_isValid() {
        let spell = spellWithSwitch(
            options: [
                SwitchOptionDefinition(
                    name: "staging",
                    command: SpellDefinition(name: "staging", script: "./stage")
                )
            ],
            defaultBranch: .key("staging")
        )

        #expect(validator.validate(manifest(spell)) == [])
    }

    private func spellWithSwitch(
        options: [SwitchOptionDefinition],
        defaultBranch: DefaultBranch = .none
    ) -> SpellDefinition {
        SpellDefinition(
            identity: SpellIdentity(name: "deploy"),
            body: SpellBody(switchBranches: SwitchDefinition(
                options: options,
                defaultBranch: defaultBranch
            ))
        )
    }

    private func manifest(_ spell: SpellDefinition) -> SpellbookManifest {
        SpellbookManifest(spells: [spell])
    }
}
