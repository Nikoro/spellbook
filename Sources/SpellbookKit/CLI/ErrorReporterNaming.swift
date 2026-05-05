enum ErrorReporterNaming {
    static func render(_ error: SpellbookError) -> RenderedError? {
        renderStructure(error)
            ?? renderShape(error)
            ?? renderNames(error)
            ?? renderDuplicates(error)
    }

    private static func renderShape(_ error: SpellbookError) -> RenderedError? {
        guard case .invalidParamsShape(let spell, let got) = error else { return nil }
        return RenderedError(
            header: "'params:' in '\(spell)' is a \(got), expected a map",
            suggestion: "Use a map form like 'params: { name: {} }'"
        )
    }

    // MARK: - Structure errors (5 cases)

    private static func renderStructure(
        _ error: SpellbookError
    ) -> RenderedError? {
        switch error {
        case .unsupportedManifestVersion(let val):
            return RenderedError(
                header: "unsupported manifest version '\(val)'",
                suggestion: "Use version: 1"
            )
        case .reservedTopLevelKey(let key):
            return RenderedError(
                header: "reserved top-level key '\(key)'",
                suggestion: "Move '\(key)' under the `spells:` key"
            )
        case .mixedParamsMode(let spell):
            return RenderedError(
                header: "mixed param modes in '\(spell)'",
                suggestion: "Use one param style consistently"
            )
        case .scriptAndSwitchCoexist(let spell):
            return RenderedError(
                header: "'\(spell)' has both script and switch",
                suggestion: "Use script or switch, not both"
            )
        case .paramsAndSwitchCoexist(let spell):
            return RenderedError(
                header: "'\(spell)' has top-level params and switch",
                suggestion: "Move params into switch branches"
            )
        default:
            return nil
        }
    }

    // MARK: - Name validation errors (4 cases)

    private static func renderNames(
        _ error: SpellbookError
    ) -> RenderedError? {
        switch error {
        case .invalidSpellName(let name):
            return RenderedError(
                header: "invalid spell name '\(name)'",
                suggestion: "Start with a letter; use letters, digits, hyphens, or underscores"
            )
        case .invalidAliasName(let spell, let alias):
            return RenderedError(
                header: "invalid alias '\(alias)' in '\(spell)'",
                suggestion: "Start with a letter; use letters, digits, hyphens, or underscores"
            )
        case .invalidParamName(let spell, let name):
            return RenderedError(
                header: "invalid param name '\(name)' in '\(spell)'",
                suggestion: "Start with a letter or underscore; use letters, digits, or underscores"
            )
        case .paramShadowsOverriddenSpell(let spell, let param):
            return RenderedError(
                header: "param '\(param)' shadows override spell '\(spell)'",
                suggestion: "Rename the param"
            )
        case .requiredParamHasDefault(let spell, let param):
            return RenderedError(
                header: "required param '\(param)' in '\(spell)' has a default",
                suggestion: "Remove the default or make the param optional"
            )
        default:
            return nil
        }
    }

    // MARK: - Duplicate/uniqueness errors (4 cases)

    private static func renderDuplicates(
        _ error: SpellbookError
    ) -> RenderedError? {
        switch error {
        case .duplicateSpellName(let name):
            return RenderedError(header: "duplicate spell name '\(name)'")
        case .duplicateParamFlag(let spell, let flag):
            return RenderedError(header: "duplicate param flag '\(flag)' in '\(spell)'")
        case .duplicatePassthrough(let spell):
            return RenderedError(
                header: "multiple ...args in '\(spell)'",
                suggestion: "Use ...args at most once per script"
            )
        case .switchDuplicateName(let spell, let name):
            return RenderedError(header: "duplicate switch option '\(name)' in '\(spell)'")
        default:
            return nil
        }
    }
}
