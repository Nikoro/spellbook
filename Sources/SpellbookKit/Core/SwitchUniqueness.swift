enum SwitchUniqueness {
    static func check(_ branches: SwitchDefinition, spell: String) -> [SpellbookError] {
        let tokens = branches.options.flatMap(names)
        return DuplicateTokens.find(tokens).map { .switchDuplicateName(spell: spell, name: $0) }
    }

    private static func names(_ option: SwitchOptionDefinition) -> [String] {
        [option.name] + option.aliases
    }
}
