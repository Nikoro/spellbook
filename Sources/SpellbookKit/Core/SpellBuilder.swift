struct SpellBuilder {
    let name: String
    let fallbackDescription: String?
    private var script: String?
    private var explicitDescription: String?
    private var aliases: [String] = []
    private var params: [ParamDefinition] = []
    private var switchBranches: SwitchDefinition?
    private var defaultNode: YAMLNode?
    private var runtime = SpellRuntimeBuilder()

    init(name: String, fallbackDescription: String?) {
        self.name = name
        self.fallbackDescription = fallbackDescription
    }

    mutating func absorb(fields: [MapEntry]) throws {
        for field in fields {
            try absorb(field)
        }
    }

    private mutating func absorb(_ field: MapEntry) throws {
        switch field.key {
        case "script": script = field.value.scalar
        case "description": explicitDescription = field.value.scalar
        case "aliases": aliases = ScalarListReader.read(field.value)
        case "params": params = try ParamSectionParser().parse(field.value, spellName: name)
        case "switch": switchBranches = try SwitchSectionParser().parse(field.value)
        case "default": defaultNode = field.value
        default: runtime.absorb(field)
        }
    }

    func build() throws -> SpellDefinition {
        try validateBodyShape()
        let identity = SpellIdentity(
            name: name,
            description: explicitDescription ?? fallbackDescription,
            aliases: aliases
        )
        let body = SpellBody(script: script, params: params, switchBranches: try resolvedSwitch())
        return SpellDefinition(identity: identity, body: body, runtime: runtime.build())
    }

    private func validateBodyShape() throws {
        guard switchBranches != nil else { return }
        if script != nil {
            throw SpellbookError.scriptAndSwitchCoexist(spell: name)
        }
        if !params.isEmpty {
            throw SpellbookError.paramsAndSwitchCoexist(spell: name)
        }
    }

    private func resolvedSwitch() throws -> SwitchDefinition? {
        guard let branches = switchBranches else { return nil }
        return SwitchDefinition(options: branches.options, defaultBranch: try resolvedDefault())
    }

    private func resolvedDefault() throws -> DefaultBranch {
        guard let node = defaultNode else { return .none }
        if case .scalar(let key) = node { return .key(key) }
        if case .map(let fields) = node {
            var builder = SpellBuilder(name: name, fallbackDescription: fallbackDescription)
            try builder.absorb(fields: fields)
            return .inline(try builder.build())
        }
        return .none
    }
}
