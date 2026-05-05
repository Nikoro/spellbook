enum ExtendsMerge {
    static func closerWins(child: SpellbookManifest, parent: SpellbookManifest) -> SpellbookManifest {
        let overriddenNames = Set(child.spells.map(\.name))
        let parentOnly = parent.spells.filter { !overriddenNames.contains($0.name) }
        return SpellbookManifest(
            version: child.version,
            extends: nil,
            spells: child.spells + parentOnly
        )
    }
}
