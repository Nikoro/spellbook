public struct ProjectState: Codable, Equatable, Sendable {
    public let spellsYamlHash: String
    public let chain: [String]
    public let spells: [String: SpellState]

    public init(
        spellsYamlHash: String,
        chain: [String],
        spells: [String: SpellState] = [:]
    ) {
        self.spellsYamlHash = spellsYamlHash
        self.chain = chain
        self.spells = spells
    }

    enum CodingKeys: String, CodingKey {
        case spellsYamlHash = "spells_yaml_hash"
        case chain
        case spells
    }
}
