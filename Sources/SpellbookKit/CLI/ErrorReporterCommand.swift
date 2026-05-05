enum ErrorReporterCommand {
    static func render(
        _ error: SpellbookError
    ) -> RenderedError? {
        renderResolution(error)
            ?? renderExec(error)
            ?? renderCLI(error)
            ?? renderMissingArgument(error)
    }

    private static func renderMissingArgument(
        _ error: SpellbookError
    ) -> RenderedError? {
        switch error {
        case .initMissingShell:
            return RenderedError(
                header: "init: missing shell argument",
                suggestion: "Usage: spells init <zsh|bash|fish>"
            )
        case .cleanRequiresArgument:
            return RenderedError(
                header: "clean: missing target",
                suggestion: "Usage: spells clean <name> | --all | --orphans"
            )
        case .completionMissingShell:
            return RenderedError(
                header: "completion: missing shell argument",
                suggestion: "Usage: spells completion <zsh|bash|fish>"
            )
        default:
            return renderCompleteError(error)
        }
    }

    private static func renderCompleteError(
        _ error: SpellbookError
    ) -> RenderedError? {
        let usage = "Usage: spells complete <wrapper> --cword <N> -- <tokens>"
        switch error {
        case .completeMissingWrapper:
            return RenderedError(header: "complete: missing wrapper name")
        case .completeMissingCword:
            return RenderedError(
                header: "complete: missing --cword argument", suggestion: usage
            )
        case .completeInvalidCword(let value):
            return RenderedError(
                header: "complete: invalid --cword value '\(value)'",
                suggestion: "Must be a non-negative integer"
            )
        case .completeMissingSeparator:
            return RenderedError(
                header: "complete: missing `--` separator", suggestion: usage
            )
        default:
            return nil
        }
    }

    // MARK: - Resolution errors (4 cases)

    private static func renderResolution(
        _ error: SpellbookError
    ) -> RenderedError? {
        switch error {
        case .spellNotFound(let name):
            return RenderedError(
                header: "spell '\(name)' not found",
                suggestion: "Check spelling or run `spells list`"
            )
        case .spellNotFoundWithSuggestions(let name, let projects):
            let list = projects.joined(separator: ", ")
            return RenderedError(
                header: "spell '\(name)' not found in current project",
                suggestion: "Available in: \(list)"
            )
        case .switchOptionNotFound(let spell, let option, let available):
            let list = available.joined(separator: ", ")
            return RenderedError(
                header: "switch option '\(option)' not found in '\(spell)'",
                suggestion: "Available options: \(list)"
            )
        case .switchRequiresOption(let spell, let available):
            let list = available.joined(separator: ", ")
            return RenderedError(
                header: "'\(spell)' requires a switch option",
                suggestion: "Available options: \(list)"
            )
        default:
            return nil
        }
    }

    // MARK: - Execution & state errors (3 cases)

    private static func renderExec(
        _ error: SpellbookError
    ) -> RenderedError? {
        switch error {
        case .scriptLaunchFailed(let shell, let reason):
            return RenderedError(
                header: "failed to launch script",
                context: "shell: \(shell)",
                body: reason
            )
        case .unsupportedStateVersion(let found, let supported):
            return RenderedError(
                header: "unsupported state version \(found)",
                suggestion: "Expected \(supported). Delete state.json and re-activate"
            )
        case .runMissingSpellName:
            return RenderedError(header: "run: missing spell name")
        default:
            return nil
        }
    }

    // MARK: - CLI command errors (4 cases)

    private static func renderCLI(
        _ error: SpellbookError
    ) -> RenderedError? {
        switch error {
        case .runMissingCwd:
            return RenderedError(header: "run: missing --cwd argument")
        case .createInvalidName(let name):
            return RenderedError(
                header: "invalid spell name '\(name)'",
                suggestion: "Start with a letter; use letters, digits, hyphens, or underscores"
            )
        case .unsupportedShell(let name):
            return RenderedError(
                header: "unsupported shell '\(name)'",
                suggestion: "Supported shells: zsh, bash, fish"
            )
        default:
            return nil
        }
    }
}
