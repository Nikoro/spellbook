public enum DiffDetector {
    public static func detect(
        fresh: ActivationResult,
        state: ProjectState?
    ) -> [DiffEntry] {
        let freshByName = Dictionary(
            uniqueKeysWithValues: fresh.manifest.spells.map { ($0.name, $0) }
        )
        guard let project = state else {
            return freshByName.keys.sorted().map { name in
                DiffEntry(name: name, kind: .added, origin: fresh.spellOrigins[name])
            }
        }
        var entries: [DiffEntry] = []
        entries.append(contentsOf: added(fresh: fresh, freshByName: freshByName, state: project))
        entries.append(contentsOf: changed(fresh: fresh, freshByName: freshByName, state: project))
        entries.append(contentsOf: removed(freshByName: freshByName, state: project))
        return entries.sorted { lhs, rhs in
            if lhs.kind != rhs.kind { return order(lhs.kind) < order(rhs.kind) }
            return lhs.name < rhs.name
        }
    }

    private static func order(_ kind: DiffEntry.Kind) -> Int {
        switch kind {
        case .added: return 0
        case .changed: return 1
        case .removed: return 2
        }
    }

    private static func added(
        fresh: ActivationResult,
        freshByName: [String: SpellDefinition],
        state: ProjectState
    ) -> [DiffEntry] {
        freshByName.keys
            .filter { state.spells[$0] == nil }
            .sorted()
            .map { DiffEntry(name: $0, kind: .added, origin: fresh.spellOrigins[$0]) }
    }

    private static func changed(
        fresh: ActivationResult,
        freshByName: [String: SpellDefinition],
        state: ProjectState
    ) -> [DiffEntry] {
        freshByName.compactMap { name, spell -> DiffEntry? in
            guard let stored = state.spells[name] else { return nil }
            let freshHash = ManifestHasher.hashSpell(spell)
            guard freshHash != stored.hash else { return nil }
            let origin = fresh.spellOrigins[name] ?? stored.origin
            return DiffEntry(name: name, kind: .changed, origin: origin)
        }
        .sorted { $0.name < $1.name }
    }

    private static func removed(
        freshByName: [String: SpellDefinition],
        state: ProjectState
    ) -> [DiffEntry] {
        state.spells.keys
            .filter { freshByName[$0] == nil }
            .sorted()
            .map { name in
                DiffEntry(name: name, kind: .removed, origin: state.spells[name]?.origin)
            }
    }
}
