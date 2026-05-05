enum ErrorReporterArgs {
    static func render(
        _ error: SpellbookError
    ) -> RenderedError? {
        renderParsing(error) ?? renderEnum(error) ?? renderValue(error)
    }

    private static func renderEnum(_ error: SpellbookError) -> RenderedError? {
        guard case .missingRequiredEnumValue(let spell, let param, let values) = error else {
            return nil
        }
        return RenderedError(
            header: "missing required param '\(param)' in '\(spell)'",
            suggestion: "Valid values: \(values.joined(separator: ", "))"
        )
    }

    // MARK: - Argument parsing errors (4 cases)

    private static func renderParsing(
        _ error: SpellbookError
    ) -> RenderedError? {
        switch error {
        case .missingRequiredParam(let spell, let param, let flags):
            let hint = flags.isEmpty ? param : flags.joined(separator: ", ")
            return RenderedError(
                header: "missing required param '\(param)' in '\(spell)'",
                suggestion: "Provide \(hint)"
            )
        case .unexpectedArgument(let spell, let value, _, let origin):
            let detail = origin == .afterStopParsingSentinel
                ? "after -- sentinel" : "in argument list"
            return RenderedError(
                header: "unexpected argument '\(value)' \(detail)",
                context: "spell '\(spell)'",
                suggestion: "Add ...args to the script to accept extra arguments"
            )
        case .flagMissingValue(let spell, let param, let flag):
            return RenderedError(
                header: "flag '\(flag)' expects a value for '\(param)'",
                context: "spell '\(spell)'",
                suggestion: "Provide a value: \(flag) <value>"
            )
        case .unsupportedEqualsForm(_, let param, let flag, _):
            return RenderedError(
                header: "equals form is not supported",
                suggestion: "Use separate tokens: \(flag) <\(param)>"
            )
        default:
            return nil
        }
    }

    // MARK: - Invalid value error (1 case)

    private static func renderValue(
        _ error: SpellbookError
    ) -> RenderedError? {
        guard case .invalidParamValue(
            let spell, let param, let value,
            let expected, let validValues, let example
        ) = error else { return nil }
        var tip = "Expected type: \(expected)"
        if !validValues.isEmpty {
            tip = "Valid values: \(validValues.joined(separator: ", "))"
        } else if let example {
            tip += " (e.g. \(example))"
        }
        return RenderedError(
            header: "invalid value '\(value)' for '\(param)'",
            context: "spell '\(spell)'",
            suggestion: tip
        )
    }
}
