public struct SpellbookValidator {
    private let pathChecker: PathBinaryChecker?

    public init(pathChecker: PathBinaryChecker? = nil) {
        self.pathChecker = pathChecker
    }

    public func validate(_ manifest: SpellbookManifest) -> [SpellbookError] {
        TopLevelUniqueness.check(manifest.spells) + manifest.spells.flatMap(validate)
    }

    private func validate(_ spell: SpellDefinition) -> [SpellbookError] {
        var errors: [SpellbookError] = []
        if !SpellName.isValid(spell.name) {
            errors.append(.invalidSpellName(name: spell.name))
        }
        for alias in spell.aliases where !SpellName.isValid(alias) {
            errors.append(.invalidAliasName(spell: spell.name, alias: alias))
        }
        errors.append(contentsOf: validateParams(spell))
        errors.append(contentsOf: validateScript(spell))
        if let branches = spell.switchBranches {
            errors.append(contentsOf: validate(branches, spell: spell.name, path: []))
        }
        if let checker = pathChecker {
            errors.append(contentsOf: PathShadowValidator.check(spell, checker: checker))
        }
        return errors
    }

    private func validateScript(_ spell: SpellDefinition) -> [SpellbookError] {
        checkPassthrough(spell.script, spell: spell.name)
    }

    private func checkPassthrough(_ script: String?, spell: String) -> [SpellbookError] {
        guard let script, ScriptPassthrough.count(in: script) > 1 else { return [] }
        return [.duplicatePassthrough(spell: spell)]
    }

    private func validateParams(_ spell: SpellDefinition) -> [SpellbookError] {
        spell.params.flatMap { validate($0, in: spell) }
            + ParamFlagUniqueness.check(spell.params, spell: spell.name)
    }

    private func validate(_ param: ParamDefinition, in spell: SpellDefinition) -> [SpellbookError] {
        var errors: [SpellbookError] = []
        if !ParamName.isValid(param.name) {
            errors.append(.invalidParamName(spell: spell.name, name: param.name))
        }
        if spell.override, param.name == spell.name {
            errors.append(.paramShadowsOverriddenSpell(spell: spell.name, param: param.name))
        }
        if param.isRequired, param.defaultValue != nil {
            errors.append(.requiredParamHasDefault(spell: spell.name, param: param.name))
        }
        return errors
    }

    private func validate(
        _ branches: SwitchDefinition,
        spell: String,
        path: [String]
    ) -> [SpellbookError] {
        SwitchUniqueness.check(branches, spell: spell)
            + DefaultBranchValidator.check(branches, spell: spell)
            + branches.options.flatMap { validate($0, spell: spell, path: path) }
    }

    private func validate(
        _ option: SwitchOptionDefinition,
        spell: String,
        path: [String]
    ) -> [SpellbookError] {
        let trail = path + [option.name]
        if let nested = option.command.switchBranches {
            return validate(nested, spell: spell, path: trail)
        }
        if option.command.script == nil {
            return [.switchLeafMissingScript(spell: spell, path: trail.joined(separator: "."))]
        }
        return checkPassthrough(option.command.script, spell: spell)
    }
}
