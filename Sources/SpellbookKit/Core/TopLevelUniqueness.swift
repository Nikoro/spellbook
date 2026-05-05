enum TopLevelUniqueness {
    static func check(_ spells: [SpellDefinition]) -> [SpellbookError] {
        let tokens = spells.flatMap(entrypoints)
        return DuplicateTokens.find(tokens).map { .duplicateSpellName(name: $0) }
    }

    private static func entrypoints(_ spell: SpellDefinition) -> [String] {
        [spell.name] + spell.aliases
    }
}
