public struct SpellLookup {
    public init() {}

    public func find(name: String, in manifest: SpellbookManifest) -> SpellDefinition? {
        if let spell = manifest.spells.first(where: { $0.name == name }) {
            return spell
        }
        return manifest.spells.first(where: { $0.aliases.contains(name) })
    }
}
