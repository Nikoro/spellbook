public enum ListResolver {
    public static func resolve(_ manifest: SpellbookManifest) -> [ListEntry] {
        manifest.spells.map { spell in
            ListEntry(
                name: spell.name,
                aliases: spell.aliases,
                description: spell.description,
                override: spell.override
            )
        }
    }
}
