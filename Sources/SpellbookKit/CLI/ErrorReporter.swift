public enum ErrorReporter {
    public static func render(
        _ error: SpellbookError,
        color: Bool
    ) -> String {
        let rendered = renderYAML(error)
            ?? renderYAMLExtra(error)
            ?? renderManifest(error)
            ?? ErrorReporterNaming.render(error)
            ?? ErrorReporterRuntime.render(error)
            ?? RenderedError(header: "\(error)")
        return rendered.formatted(color: color)
    }

    // MARK: - YAML errors (3 cases)

    static func renderYAML(
        _ error: SpellbookError
    ) -> RenderedError? {
        switch error {
        case .tabIndentation(let line):
            return RenderedError(
                header: "tab indentation is not allowed",
                context: "line \(line)",
                suggestion: "Replace tabs with spaces (2 or 4)"
            )
        case .unmatchedQuote(let line, let column):
            return RenderedError(
                header: "unmatched quote",
                context: "line \(line), column \(column)",
                suggestion: "Close the quote on the same line"
            )
        case .missingColon(let line):
            return RenderedError(
                header: "expected ':' after key",
                context: "line \(line)",
                suggestion: "Add a colon after the key name"
            )
        default:
            return nil
        }
    }

    // MARK: - YAML errors continued (3 cases)

    static func renderYAMLExtra(
        _ error: SpellbookError
    ) -> RenderedError? {
        switch error {
        case .unexpectedIndent(let line):
            return RenderedError(
                header: "unexpected indentation",
                context: "line \(line)",
                suggestion: "Check indentation matches the parent block"
            )
        case .unclosedFlowSequence(let line):
            return RenderedError(
                header: "unclosed flow sequence",
                context: "line \(line)",
                suggestion: "Add a closing ']'"
            )
        case .unsupportedSequenceItem(let line):
            return RenderedError(
                header: "unsupported sequence item",
                context: "line \(line)",
                suggestion: "Use a scalar value or a map instead"
            )
        default:
            return nil
        }
    }

    // MARK: - Manifest errors (6 cases)

    static func renderManifest(
        _ error: SpellbookError
    ) -> RenderedError? {
        switch error {
        case .walkUpTooDeep(let path):
            return RenderedError(header: "manifest search exceeded depth limit", context: path)
        case .noManifestFound:
            return RenderedError(
                header: "no spells.yaml found",
                suggestion: "Run `spells create` to create one"
            )
        case .manifestAlreadyExists(let path):
            return RenderedError(header: "manifest already exists", context: path)
        case .missingExtendsParent(let path):
            return RenderedError(
                header: "extends parent not found",
                context: path,
                suggestion: "Check the extends path in your manifest"
            )
        case .extendsCycle(let path):
            return RenderedError(header: "extends cycle detected", context: path)
        case .mixedManifestMode:
            return RenderedError(
                header: "mixed manifest mode",
                suggestion: "Move all spells under `spells:`, or remove it"
            )
        default:
            return nil
        }
    }
}
