enum DoctorSemanticChecks {
    static func warnings(
        manifest: SpellbookManifest,
        pathChecker: PathBinaryChecker?
    ) -> [DiagnosticItem] {
        var items: [DiagnosticItem] = []
        items.append(contentsOf: pathShadowWarnings(manifest: manifest, pathChecker: pathChecker))
        items.append(contentsOf: overridePlaceholderWarnings(manifest: manifest))
        items.append(contentsOf: unusedParamWarnings(manifest: manifest))
        items.append(contentsOf: unknownPlaceholderWarnings(manifest: manifest))
        items.append(contentsOf: caseCollisionWarnings(manifest: manifest))
        return items
    }

    private static func pathShadowWarnings(
        manifest: SpellbookManifest,
        pathChecker: PathBinaryChecker?
    ) -> [DiagnosticItem] {
        guard let checker = pathChecker else { return [] }
        return manifest.spells.flatMap { spell -> [DiagnosticItem] in
            PathShadowValidator.check(spell, checker: checker).map { error in
                DiagnosticItem(
                    severity: .warning,
                    category: .semantic,
                    message: "Shadowing: \(error)"
                )
            }
        }
    }

    private static func overridePlaceholderWarnings(
        manifest: SpellbookManifest
    ) -> [DiagnosticItem] {
        manifest.spells.compactMap { spell -> DiagnosticItem? in
            guard spell.override else { return nil }
            let placeholder = "{{\(spell.name)}}"
            let hasPlaceholder = terminalScripts(for: spell).contains { $0.contains(placeholder) }
            guard !hasPlaceholder else { return nil }
            return DiagnosticItem(
                severity: .warning,
                category: .semantic,
                message: "Override `\(spell.name)` does not reference \(placeholder) in any script"
            )
        }
    }

    private static func unknownPlaceholderWarnings(
        manifest: SpellbookManifest
    ) -> [DiagnosticItem] {
        manifest.spells.flatMap { spell -> [DiagnosticItem] in
            let unknown = UnknownPlaceholderScanner.unknownReferences(
                in: spell, scripts: terminalScripts(for: spell)
            )
            return unknown.map { name in
                DiagnosticItem(
                    severity: .warning,
                    category: .semantic,
                    message: "Unknown placeholder `{{\(name)}}` in spell `\(spell.name)` — will pass through unchanged"
                )
            }
        }
    }

    private static func unusedParamWarnings(
        manifest: SpellbookManifest
    ) -> [DiagnosticItem] {
        manifest.spells.flatMap { spell -> [DiagnosticItem] in
            let scripts = terminalScripts(for: spell)
            return spell.params.compactMap { param -> DiagnosticItem? in
                let placeholder = "{{\(param.name)}}"
                let used = scripts.contains { $0.contains(placeholder) }
                guard !used else { return nil }
                return DiagnosticItem(
                    severity: .warning,
                    category: .semantic,
                    message: "Param `\(param.name)` in spell `\(spell.name)` is not referenced by \(placeholder)"
                )
            }
        }
    }

    private static func caseCollisionWarnings(
        manifest: SpellbookManifest
    ) -> [DiagnosticItem] {
        var entrypoints: [(String, String)] = []
        for spell in manifest.spells {
            entrypoints.append((spell.name.lowercased(), spell.name))
            for alias in spell.aliases {
                entrypoints.append((alias.lowercased(), alias))
            }
        }
        var seen: [String: String] = [:]
        var items: [DiagnosticItem] = []
        for (lower, original) in entrypoints {
            if let existing = seen[lower], existing != original {
                items.append(DiagnosticItem(
                    severity: .warning,
                    category: .semantic,
                    message: "Case collision: `\(existing)` and `\(original)` differ only by case"
                ))
            } else {
                seen[lower] = original
            }
        }
        return items
    }

    private static func terminalScripts(for spell: SpellDefinition) -> [String] {
        var scripts: [String] = []
        if let script = spell.script { scripts.append(script) }
        if let branches = spell.switchBranches {
            collectScripts(from: branches, into: &scripts)
        }
        return scripts
    }

    private static func collectScripts(from branches: SwitchDefinition, into scripts: inout [String]) {
        for option in branches.options {
            if let script = option.command.script {
                scripts.append(script)
            }
            if let nested = option.command.switchBranches {
                collectScripts(from: nested, into: &scripts)
            }
        }
        switch branches.defaultBranch {
        case .none, .key:
            break
        case .inline(let command):
            if let script = command.script {
                scripts.append(script)
            }
        }
    }
}
