public struct SpellbookParser {
    public init() {}

    public func parse(_ root: YAMLNode) throws -> SpellbookManifest {
        guard case .map(let entries) = root else {
            return SpellbookManifest(spells: [])
        }
        return try hasCanonicalSpellsKey(entries)
            ? parseCanonical(entries)
            : parseCompact(entries)
    }

    private func hasCanonicalSpellsKey(_ entries: [MapEntry]) -> Bool {
        entries.contains { $0.key == "spells" }
    }

    private func parseCanonical(_ entries: [MapEntry]) throws -> SpellbookManifest {
        var version = 1
        var extends: String?
        var spellEntries: [MapEntry] = []
        for entry in entries {
            switch entry.key {
            case "spells":
                spellEntries = entry.value.map ?? []
            case "version":
                version = try readVersion(entry.value)
            case "extends":
                extends = entry.value.scalar
            default:
                throw canonicalTopLevelError(for: entry.key)
            }
        }
        let spells = try spellEntries.map(parseSpell)
        return SpellbookManifest(version: version, extends: extends, spells: spells)
    }

    private func parseCompact(_ entries: [MapEntry]) throws -> SpellbookManifest {
        let spells = try entries.map(parseSpell)
        return SpellbookManifest(spells: spells)
    }

    private func parseSpell(_ entry: MapEntry) throws -> SpellDefinition {
        if case .scalar(let script) = entry.value {
            return SpellDefinition(name: entry.key, description: entry.description, script: script)
        }
        guard case .map(let fields) = entry.value else {
            return SpellDefinition(name: entry.key, description: entry.description)
        }
        return try buildSpell(name: entry.key, comment: entry.description, fields: fields)
    }

    private func buildSpell(
        name: String,
        comment: String?,
        fields: [MapEntry]
    ) throws -> SpellDefinition {
        var builder = SpellBuilder(name: name, fallbackDescription: comment)
        try builder.absorb(fields: fields)
        return try builder.build()
    }

    private func readVersion(_ node: YAMLNode) throws -> Int {
        let raw = node.scalar ?? ""
        guard raw == "1" else {
            throw SpellbookError.unsupportedManifestVersion(value: raw)
        }
        return 1
    }

    private func canonicalTopLevelError(for key: String) -> SpellbookError {
        let reservedFutureKeys: Set<String> = ["env", "settings", "defaults"]
        if reservedFutureKeys.contains(key) {
            return SpellbookError.reservedTopLevelKey(key: key)
        }
        return SpellbookError.mixedManifestMode
    }
}
