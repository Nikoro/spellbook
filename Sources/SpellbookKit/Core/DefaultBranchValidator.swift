enum DefaultBranchValidator {
    static func check(_ branches: SwitchDefinition, spell: String) -> [SpellbookError] {
        guard case .key(let key) = branches.defaultBranch else { return [] }
        if branches.options.contains(where: { $0.name == key }) { return [] }
        if let canonical = canonical(forAlias: key, in: branches.options) {
            return [.defaultKeyIsAlias(spell: spell, alias: key, canonical: canonical)]
        }
        return [.defaultKeyNotFound(spell: spell, key: key)]
    }

    private static func canonical(
        forAlias alias: String,
        in options: [SwitchOptionDefinition]
    ) -> String? {
        options.first { $0.aliases.contains(alias) }?.name
    }
}
