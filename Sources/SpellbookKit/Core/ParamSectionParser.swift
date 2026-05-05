struct ParamSectionParser {
    private static let groupKeys: Set<String> = ["required", "optional"]

    func parse(_ node: YAMLNode, spellName: String) throws -> [ParamDefinition] {
        switch node {
        case .map(let entries):
            return try isExplicitMode(entries)
                ? parseExplicit(entries, spellName: spellName)
                : entries.map(parseInferred)
        case .null:
            return []
        case .sequence:
            throw SpellbookError.invalidParamsShape(spell: spellName, got: "sequence")
        case .scalar:
            throw SpellbookError.invalidParamsShape(spell: spellName, got: "scalar")
        }
    }

    private func isExplicitMode(_ entries: [MapEntry]) -> Bool {
        entries.contains { Self.groupKeys.contains($0.key) }
    }

    private func parseExplicit(
        _ entries: [MapEntry],
        spellName: String
    ) throws -> [ParamDefinition] {
        var result: [ParamDefinition] = []
        for entry in entries {
            switch entry.key {
            case "required":
                result.append(contentsOf: parseGroup(entry.value, isRequired: true))
            case "optional":
                result.append(contentsOf: parseGroup(entry.value, isRequired: false))
            default:
                throw SpellbookError.mixedParamsMode(spell: spellName)
            }
        }
        return result
    }

    private func parseGroup(_ node: YAMLNode, isRequired: Bool) -> [ParamDefinition] {
        guard case .map(let entries) = node else { return [] }
        return entries.map { entry in
            buildParam(name: entry.key, body: entry.value, isRequired: isRequired)
        }
    }

    private func parseInferred(_ entry: MapEntry) -> ParamDefinition {
        let attributes = ParamAttributesReader.read(entry.value)
        return buildParam(name: entry.key, attributes: attributes, isRequired: attributes.inferredIsRequired)
    }

    private func buildParam(
        name: String,
        body: YAMLNode,
        isRequired: Bool
    ) -> ParamDefinition {
        buildParam(name: name, attributes: ParamAttributesReader.read(body), isRequired: isRequired)
    }

    private func buildParam(
        name: String,
        attributes: ParamAttributes,
        isRequired: Bool
    ) -> ParamDefinition {
        ParamDefinition(
            name: name,
            description: attributes.description,
            shape: attributes.shape(isRequired: isRequired),
            schema: attributes.schema
        )
    }
}
