import Testing
@testable import SpellbookKit

struct ErrorSnapshotRuntimeTests {

    // MARK: - Naming continued

    @Test func invalidParamName() {
        snap(.invalidParamName(spell: "greet", name: "1x"), named: "error-invalidParamName")
    }

    @Test func paramShadowsOverride() {
        snap(.paramShadowsOverriddenSpell(spell: "git", param: "git"), named: "error-paramShadowsOverride")
    }

    @Test func duplicateParamFlag() {
        snap(.duplicateParamFlag(spell: "deploy", flag: "-e"), named: "error-duplicateParamFlag")
    }

    @Test func requiredParamHasDefault() {
        snap(.requiredParamHasDefault(spell: "build", param: "target"), named: "error-requiredParamHasDefault")
    }

    @Test func duplicatePassthrough() {
        snap(.duplicatePassthrough(spell: "run"), named: "error-duplicatePassthrough")
    }

    @Test func switchDuplicateName() {
        snap(.switchDuplicateName(spell: "deploy", name: "staging"), named: "error-switchDuplicateName")
    }

    // MARK: - Switch errors

    @Test func defaultKeyNotFound() {
        snap(.defaultKeyNotFound(spell: "deploy", key: "prod"), named: "error-defaultKeyNotFound")
    }

    @Test func defaultKeyIsAlias() {
        snap(
            .defaultKeyIsAlias(spell: "deploy", alias: "stg", canonical: "staging"),
            named: "error-defaultKeyIsAlias"
        )
    }

    @Test func selectionCancelled() {
        snap(.selectionCancelled(spell: "deploy"), named: "error-selectionCancelled")
    }

    // MARK: - Shadow errors

    @Test func spellIsShellStateBuiltin() {
        snap(.spellIsShellStateBuiltin(spell: "cd"), named: "error-spellIsShellStateBuiltin")
    }

    @Test func aliasIsShellStateBuiltin() {
        snap(.aliasIsShellStateBuiltin(spell: "go", alias: "cd"), named: "error-aliasIsShellStateBuiltin")
    }

    @Test func spellShadowsPathBinary() {
        snap(.spellShadowsPathBinary(spell: "git"), named: "error-spellShadowsPathBinary")
    }

    @Test func aliasShadowsPathBinary() {
        snap(.aliasShadowsPathBinary(spell: "myls", alias: "ls"), named: "error-aliasShadowsPathBinary")
    }

    // MARK: - Argument errors

    @Test func missingRequiredParam() {
        snap(
            .missingRequiredParam(spell: "deploy", param: "env", flags: ["--env", "-e"]),
            named: "error-missingRequiredParam"
        )
    }

    @Test func unexpectedArgument() {
        snap(
            .unexpectedArgument(spell: "build", value: "extra", index: 0, origin: .regular),
            named: "error-unexpectedArgument"
        )
    }

    @Test func flagMissingValue() {
        snap(
            .flagMissingValue(spell: "deploy", param: "env", flag: "--env"),
            named: "error-flagMissingValue"
        )
    }

    @Test func unsupportedEqualsForm() {
        snap(
            .unsupportedEqualsForm(spell: "deploy", param: "env", flag: "--env", value: "prod"),
            named: "error-unsupportedEqualsForm"
        )
    }

    @Test func invalidParamValue() {
        snap(
            .invalidParamValue(
                spell: "deploy", param: "count", value: "abc",
                expected: .int, validValues: [], example: "42"
            ),
            named: "error-invalidParamValue"
        )
    }

    // MARK: - Resolution & command errors

    @Test func spellNotFound() {
        snap(.spellNotFound(name: "bild"), named: "error-spellNotFound")
    }

    @Test func spellNotFoundWithSuggestions() {
        snap(
            .spellNotFoundWithSuggestions(name: "build", projects: ["/other/project"]),
            named: "error-spellNotFoundWithSuggestions"
        )
    }

    @Test func switchOptionNotFound() {
        snap(
            .switchOptionNotFound(spell: "deploy", option: "qa", available: ["staging", "production"]),
            named: "error-switchOptionNotFound"
        )
    }

    @Test func switchRequiresOption() {
        snap(
            .switchRequiresOption(spell: "deploy", available: ["staging", "production"]),
            named: "error-switchRequiresOption"
        )
    }

    @Test func scriptLaunchFailed() {
        snap(.scriptLaunchFailed(shell: "bash", reason: "not found"), named: "error-scriptLaunchFailed")
    }

    @Test func unsupportedStateVersion() {
        snap(.unsupportedStateVersion(found: 99, supported: 1), named: "error-unsupportedStateVersion")
    }

    @Test func runMissingSpellName() {
        snap(.runMissingSpellName, named: "error-runMissingSpellName")
    }

    @Test func runMissingCwd() {
        snap(.runMissingCwd, named: "error-runMissingCwd")
    }

    @Test func createInvalidName() {
        snap(.createInvalidName(name: "123"), named: "error-createInvalidName")
    }

    @Test func unsupportedShell() {
        snap(.unsupportedShell(name: "nushell"), named: "error-unsupportedShell")
    }

    @Test func initMissingShell() {
        snap(.initMissingShell, named: "error-initMissingShell")
    }

    // MARK: - Helper

    private func snap(_ error: SpellbookError, named name: String) {
        let output = ErrorReporter.render(error, color: false)
        Snapshot.assert(output, named: name)
    }
}
