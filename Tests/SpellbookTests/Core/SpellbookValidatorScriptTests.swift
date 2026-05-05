import Testing
@testable import SpellbookKit

struct SpellbookValidatorScriptTests {
    private let validator = SpellbookValidator()

    @Test func script_singlePassthrough_isValid() {
        let spell = spellWithScript("./wrap ...args")
        #expect(validator.validate(manifest(spell)) == [])
    }

    @Test func script_duplicatePassthrough_isError() {
        let spell = spellWithScript("./wrap ...args && ./log ...args")
        #expect(validator.validate(manifest(spell)) == [.duplicatePassthrough(spell: "wrap")])
    }

    @Test func script_withoutPassthrough_isValid() {
        let spell = spellWithScript("./wrap")
        #expect(validator.validate(manifest(spell)) == [])
    }

    @Test func switchLeaf_duplicatePassthrough_isError() {
        let spell = SpellDefinition(
            identity: SpellIdentity(name: "wrap"),
            body: SpellBody(switchBranches: SwitchDefinition(options: [
                SwitchOptionDefinition(
                    name: "test",
                    command: SpellDefinition(name: "test", script: "./a ...args ...args")
                )
            ]))
        )
        #expect(validator.validate(manifest(spell)) == [.duplicatePassthrough(spell: "wrap")])
    }

    private func spellWithScript(_ script: String) -> SpellDefinition {
        SpellDefinition(name: "wrap", script: script)
    }

    private func manifest(_ spell: SpellDefinition) -> SpellbookManifest {
        SpellbookManifest(spells: [spell])
    }
}
