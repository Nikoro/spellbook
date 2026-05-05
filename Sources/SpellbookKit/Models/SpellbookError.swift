public enum SpellbookError: Error, Equatable, Sendable {
    case tabIndentation(line: Int)
    case unmatchedQuote(line: Int, column: Int)
    case missingColon(line: Int)
    case unexpectedIndent(line: Int)
    case unclosedFlowSequence(line: Int)
    case unsupportedSequenceItem(line: Int)
    case walkUpTooDeep(path: String)
    case mixedManifestMode
    case unsupportedManifestVersion(value: String)
    case reservedTopLevelKey(key: String)
    case mixedParamsMode(spell: String)
    case invalidParamsShape(spell: String, got: String)
    case scriptAndSwitchCoexist(spell: String)
    case paramsAndSwitchCoexist(spell: String)
    case switchLeafMissingScript(spell: String, path: String)
    case switchDuplicateName(spell: String, name: String)
    case defaultKeyNotFound(spell: String, key: String)
    case defaultKeyIsAlias(spell: String, alias: String, canonical: String)
    case invalidSpellName(name: String)
    case invalidAliasName(spell: String, alias: String)
    case duplicateSpellName(name: String)
    case invalidParamName(spell: String, name: String)
    case paramShadowsOverriddenSpell(spell: String, param: String)
    case duplicateParamFlag(spell: String, flag: String)
    case requiredParamHasDefault(spell: String, param: String)
    case duplicatePassthrough(spell: String)
    case missingExtendsParent(path: String)
    case extendsCycle(path: String)
    case spellIsShellStateBuiltin(spell: String)
    case aliasIsShellStateBuiltin(spell: String, alias: String)
    case spellShadowsPathBinary(spell: String)
    case aliasShadowsPathBinary(spell: String, alias: String)
    case missingRequiredParam(spell: String, param: String, flags: [String])
    case missingRequiredEnumValue(spell: String, param: String, values: [String])
    case unexpectedArgument(
        spell: String,
        value: String,
        index: Int,
        origin: UnexpectedArgumentOrigin
    )
    case flagMissingValue(spell: String, param: String, flag: String)
    case unsupportedEqualsForm(spell: String, param: String, flag: String, value: String)
    case invalidParamValue(
        spell: String,
        param: String,
        value: String,
        expected: ParamType,
        validValues: [String],
        example: String?
    )
    case noManifestFound
    case spellNotFound(name: String)
    case switchOptionNotFound(spell: String, option: String, available: [String])
    case switchRequiresOption(spell: String, available: [String])
    case selectionCancelled(spell: String)
    case scriptLaunchFailed(shell: String, reason: String)
    case unsupportedStateVersion(found: Int, supported: Int)
    case runMissingSpellName
    case runMissingCwd
    case spellNotFoundWithSuggestions(name: String, projects: [String])
    case manifestAlreadyExists(path: String)
    case createInvalidName(name: String)
    case unsupportedShell(name: String)
    case initMissingShell
    case cleanRequiresArgument
    case completionMissingShell
    case completeMissingWrapper
    case completeMissingCword
    case completeInvalidCword(value: String)
    case completeMissingSeparator
    case ttyUnavailable
}
