import Testing
@testable import SpellbookKit

struct SwitchNavigatorPickerTests {

    // MARK: - Picker selects option

    @Test func pickerSelects_usesChosenOption() throws {
        let provider = MockChoiceProvider()
        provider.outcome = .selected(1)
        let nav = SwitchNavigator(choiceProvider: provider)
        let spell = switchSpell(["dev", "prod"])

        let result = try nav.resolve(spell: spell, argv: [], spellName: "deploy")

        #expect(result.terminal.script == "run prod")
        #expect(provider.chosenOptions == ["dev", "prod"])
    }

    @Test func pickerSelects_passesSpellNameAsPrompt() throws {
        let provider = MockChoiceProvider()
        provider.outcome = .selected(0)
        let nav = SwitchNavigator(choiceProvider: provider)
        let spell = switchSpell(["dev"])

        _ = try nav.resolve(spell: spell, argv: [], spellName: "deploy")

        #expect(provider.chosenPrompt == "deploy")
    }

    // MARK: - Picker cancelled

    @Test func pickerCancelled_throwsSelectionCancelled() {
        let provider = MockChoiceProvider()
        provider.outcome = .cancelled
        let nav = SwitchNavigator(choiceProvider: provider)
        let spell = switchSpell(["dev", "prod"])

        #expect(throws: SpellbookError.selectionCancelled(spell: "deploy")) {
            try nav.resolve(spell: spell, argv: [], spellName: "deploy")
        }
    }

    // MARK: - Picker unavailable

    @Test func pickerUnavailable_fallsToSwitchRequiresOption() {
        let provider = MockChoiceProvider()
        provider.outcome = .unavailable
        let nav = SwitchNavigator(choiceProvider: provider)
        let spell = switchSpell(["dev", "prod"])

        #expect(throws: SpellbookError.switchRequiresOption(spell: "deploy", available: ["dev", "prod"])) {
            try nav.resolve(spell: spell, argv: [], spellName: "deploy")
        }
    }

    // MARK: - Picker not called when arg matches

    @Test func argMatches_pickerNotCalled() throws {
        let provider = MockChoiceProvider()
        let nav = SwitchNavigator(choiceProvider: provider)
        let spell = switchSpell(["dev", "prod"])

        _ = try nav.resolve(spell: spell, argv: ["dev"], spellName: "deploy")

        #expect(provider.callCount == 0)
    }

    // MARK: - Picker not called when default exists

    @Test func defaultExists_pickerNotCalled() throws {
        let provider = MockChoiceProvider()
        let nav = SwitchNavigator(choiceProvider: provider)
        let spell = switchSpell(["dev", "prod"], defaultBranch: .key("dev"))

        _ = try nav.resolve(spell: spell, argv: [], spellName: "deploy")

        #expect(provider.callCount == 0)
    }

    // MARK: - Helpers

    private func switchSpell(
        _ names: [String],
        defaultBranch: DefaultBranch = .none
    ) -> SpellDefinition {
        let options = names.map {
            SwitchOptionDefinition(
                name: $0,
                command: SpellDefinition(name: $0, script: "run \($0)")
            )
        }
        return SpellDefinition(
            identity: SpellIdentity(name: "deploy"),
            body: SpellBody(
                switchBranches: SwitchDefinition(
                    options: options, defaultBranch: defaultBranch
                )
            )
        )
    }
}
