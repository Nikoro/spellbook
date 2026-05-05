struct SwitchSectionParser {
    func parse(_ node: YAMLNode) throws -> SwitchDefinition? {
        guard case .map(let entries) = node else { return nil }
        let options = try entries.map(parseOption)
        return SwitchDefinition(options: options)
    }

    private func parseOption(_ entry: MapEntry) throws -> SwitchOptionDefinition {
        var builder = SpellBuilder(name: entry.key, fallbackDescription: entry.description)
        try builder.absorb(fields: optionFields(from: entry.value))
        let command = try builder.build()
        return SwitchOptionDefinition(
            name: command.name,
            aliases: command.aliases,
            description: command.description,
            command: command
        )
    }

    private func optionFields(from node: YAMLNode) -> [MapEntry] {
        if case .map(let fields) = node { return fields }
        if case .scalar(let script) = node {
            return [MapEntry(key: "script", value: .scalar(script))]
        }
        return []
    }
}
