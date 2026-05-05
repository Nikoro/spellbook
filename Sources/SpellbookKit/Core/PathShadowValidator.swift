enum PathShadowValidator {
    static func check(
        _ spell: SpellDefinition,
        checker: PathBinaryChecker
    ) -> [SpellbookError] {
        denylistErrors(for: spell)
            + nameError(for: spell, checker: checker)
            + aliasDenylistErrors(for: spell)
            + aliasPathErrors(for: spell, checker: checker)
    }

    // MARK: - Shell-state denylist

    private static func denylistErrors(
        for spell: SpellDefinition
    ) -> [SpellbookError] {
        guard ShellStateDenylist.contains(spell.name) else { return [] }
        return [.spellIsShellStateBuiltin(spell: spell.name)]
    }

    private static func aliasDenylistErrors(
        for spell: SpellDefinition
    ) -> [SpellbookError] {
        spell.aliases
            .filter(ShellStateDenylist.contains)
            .map { .aliasIsShellStateBuiltin(spell: spell.name, alias: $0) }
    }

    // MARK: - Path shadow

    private static func nameError(
        for spell: SpellDefinition,
        checker: PathBinaryChecker
    ) -> [SpellbookError] {
        guard !ShellStateDenylist.contains(spell.name),
              !spell.override,
              checker.isInPath(spell.name) else { return [] }
        return [.spellShadowsPathBinary(spell: spell.name)]
    }

    private static func aliasPathErrors(
        for spell: SpellDefinition,
        checker: PathBinaryChecker
    ) -> [SpellbookError] {
        spell.aliases
            .filter { !ShellStateDenylist.contains($0) && checker.isInPath($0) }
            .map { .aliasShadowsPathBinary(spell: spell.name, alias: $0) }
    }
}
