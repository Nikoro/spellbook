enum ErrorReporterRuntime {
    static func render(_ error: SpellbookError) -> RenderedError? {
        renderSwitch(error)
            ?? renderShadow(error)
            ?? ErrorReporterArgs.render(error)
            ?? ErrorReporterCommand.render(error)
    }

    // MARK: - Switch errors (4 cases)

    private static func renderSwitch(
        _ error: SpellbookError
    ) -> RenderedError? {
        switch error {
        case .switchLeafMissingScript(let spell, let path):
            return RenderedError(
                header: "switch leaf '\(path)' in '\(spell)' has no script",
                suggestion: "Add a script to the leaf branch"
            )
        case .defaultKeyNotFound(let spell, let key):
            return RenderedError(
                header: "default key '\(key)' not found in '\(spell)'",
                suggestion: "Use an existing switch option name"
            )
        case .defaultKeyIsAlias(let spell, let alias, let canonical):
            return RenderedError(
                header: "default '\(alias)' in '\(spell)' is an alias",
                suggestion: "Use the canonical name '\(canonical)' instead"
            )
        case .selectionCancelled(let spell):
            return RenderedError(header: "selection cancelled for '\(spell)'")
        default:
            return nil
        }
    }

    // MARK: - Shadow & builtin errors (4 cases)

    private static func renderShadow(
        _ error: SpellbookError
    ) -> RenderedError? {
        switch error {
        case .spellIsShellStateBuiltin(let spell):
            return RenderedError(
                header: "'\(spell)' is a shell builtin",
                suggestion: "Choose a different spell name"
            )
        case .aliasIsShellStateBuiltin(let spell, let alias):
            return RenderedError(
                header: "alias '\(alias)' of '\(spell)' is a shell builtin",
                suggestion: "Choose a different alias"
            )
        case .spellShadowsPathBinary(let spell):
            return RenderedError(
                header: "'\(spell)' shadows a PATH binary",
                suggestion: "Add `override: true` or choose a different name"
            )
        case .aliasShadowsPathBinary(let spell, let alias):
            return RenderedError(
                header: "alias '\(alias)' of '\(spell)' shadows a PATH binary",
                suggestion: "Remove the alias; aliases cannot use override"
            )
        default:
            return nil
        }
    }
}
