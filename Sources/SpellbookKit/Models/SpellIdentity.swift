public struct SpellIdentity: Equatable, Sendable {
    public let name: String
    public let description: String?
    public let aliases: [String]

    public init(name: String, description: String? = nil, aliases: [String] = []) {
        self.name = name
        self.description = description
        self.aliases = aliases
    }
}
