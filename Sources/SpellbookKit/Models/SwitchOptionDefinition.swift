public struct SwitchOptionDefinition: Equatable, Sendable {
    public let name: String
    public let aliases: [String]
    public let description: String?
    public let command: SpellDefinition

    public init(
        name: String,
        aliases: [String] = [],
        description: String? = nil,
        command: SpellDefinition
    ) {
        self.name = name
        self.aliases = aliases
        self.description = description
        self.command = command
    }
}
