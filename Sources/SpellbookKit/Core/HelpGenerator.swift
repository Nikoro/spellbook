public enum HelpGenerator {
    public static func spellHelp(_ spell: SpellDefinition) -> String {
        var lines: [String] = []
        lines.append(headerLine(spell))
        if !spell.aliases.isEmpty {
            lines.append("Aliases: \(spell.aliases.joined(separator: ", "))")
        }
        lines.append(contentsOf: paramLines(spell.params))
        lines.append(contentsOf: switchLines(spell.switchBranches))
        return lines.joined(separator: "\n")
    }

    public static func aliasHelp(
        name: String,
        canonical: SpellDefinition
    ) -> String {
        var lines = ["\(name) is an alias for \(canonical.name)", ""]
        lines.append(spellHelp(canonical))
        return lines.joined(separator: "\n")
    }

    // MARK: - Header

    private static func headerLine(_ spell: SpellDefinition) -> String {
        if let desc = spell.description {
            return "\(spell.name) — \(desc)"
        }
        return spell.name
    }

    // MARK: - Params

    private static func paramLines(
        _ params: [ParamDefinition]
    ) -> [String] {
        guard !params.isEmpty else { return [] }
        var lines = ["", "Parameters:"]
        for param in params {
            lines.append(formatParam(param))
        }
        return lines
    }

    private static func formatParam(
        _ param: ParamDefinition
    ) -> String {
        var label = "  "
        if !param.flags.isEmpty {
            label += param.flags.joined(separator: ", ")
        } else {
            label += "<\(param.name)>"
        }
        label += " <\(param.type)>"
        var parts = [label]
        if let desc = param.description { parts.append(desc) }
        if param.isRequired {
            parts.append("(required)")
        } else if let def = param.defaultValue {
            parts.append("(default: \(def))")
        }
        return parts.joined(separator: "  ")
    }

    // MARK: - Switches

    private static func switchLines(
        _ branches: SwitchDefinition?
    ) -> [String] {
        guard let branches else { return [] }
        var lines = ["", "Commands:"]
        for option in branches.options {
            lines.append(formatOption(option))
        }
        if case .key(let key) = branches.defaultBranch {
            lines.append("  Default: \(key)")
        }
        return lines
    }

    private static func formatOption(
        _ option: SwitchOptionDefinition
    ) -> String {
        var line = "  \(option.name)"
        if !option.aliases.isEmpty {
            line += " (\(option.aliases.joined(separator: ", ")))"
        }
        if let desc = option.description {
            line += "  \(desc)"
        }
        return line
    }
}
