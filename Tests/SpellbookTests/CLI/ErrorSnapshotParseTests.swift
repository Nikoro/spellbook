import Testing
@testable import SpellbookKit

struct ErrorSnapshotParseTests {

    // MARK: - YAML errors

    @Test func tabIndentation() {
        snap(.tabIndentation(line: 3), named: "error-tabIndentation")
    }

    @Test func unmatchedQuote() {
        snap(.unmatchedQuote(line: 5, column: 12), named: "error-unmatchedQuote")
    }

    @Test func missingColon() {
        snap(.missingColon(line: 2), named: "error-missingColon")
    }

    @Test func unexpectedIndent() {
        snap(.unexpectedIndent(line: 7), named: "error-unexpectedIndent")
    }

    @Test func unclosedFlowSequence() {
        snap(.unclosedFlowSequence(line: 4), named: "error-unclosedFlowSequence")
    }

    @Test func unsupportedSequenceItem() {
        snap(.unsupportedSequenceItem(line: 9), named: "error-unsupportedSequenceItem")
    }

    // MARK: - Manifest errors

    @Test func walkUpTooDeep() {
        snap(.walkUpTooDeep(path: "/very/deep/path"), named: "error-walkUpTooDeep")
    }

    @Test func noManifestFound() {
        snap(.noManifestFound, named: "error-noManifestFound")
    }

    @Test func manifestAlreadyExists() {
        snap(.manifestAlreadyExists(path: "/project/spells.yaml"), named: "error-manifestAlreadyExists")
    }

    @Test func missingExtendsParent() {
        snap(.missingExtendsParent(path: "../shared"), named: "error-missingExtendsParent")
    }

    @Test func extendsCycle() {
        snap(.extendsCycle(path: "/a -> /b -> /a"), named: "error-extendsCycle")
    }

    @Test func mixedManifestMode() {
        snap(.mixedManifestMode, named: "error-mixedManifestMode")
    }

    // MARK: - Structure errors

    @Test func unsupportedManifestVersion() {
        snap(.unsupportedManifestVersion(value: "2"), named: "error-unsupportedManifestVersion")
    }

    @Test func reservedTopLevelKey() {
        snap(.reservedTopLevelKey(key: "env"), named: "error-reservedTopLevelKey")
    }

    @Test func mixedParamsMode() {
        snap(.mixedParamsMode(spell: "deploy"), named: "error-mixedParamsMode")
    }

    @Test func scriptAndSwitchCoexist() {
        snap(.scriptAndSwitchCoexist(spell: "build"), named: "error-scriptAndSwitchCoexist")
    }

    @Test func paramsAndSwitchCoexist() {
        snap(.paramsAndSwitchCoexist(spell: "run"), named: "error-paramsAndSwitchCoexist")
    }

    @Test func switchLeafMissingScript() {
        snap(
            .switchLeafMissingScript(spell: "deploy", path: "deploy.staging"),
            named: "error-switchLeafMissingScript"
        )
    }

    // MARK: - Naming errors

    @Test func invalidSpellName() {
        snap(.invalidSpellName(name: "123bad"), named: "error-invalidSpellName")
    }

    @Test func duplicateSpellName() {
        snap(.duplicateSpellName(name: "build"), named: "error-duplicateSpellName")
    }

    // MARK: - Helper

    private func snap(_ error: SpellbookError, named name: String) {
        let output = ErrorReporter.render(error, color: false)
        Snapshot.assert(output, named: name)
    }
}
