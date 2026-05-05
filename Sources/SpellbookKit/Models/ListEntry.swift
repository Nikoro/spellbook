public struct ListEntry: Equatable, Sendable {
    public let name: String
    public let aliases: [String]
    public let description: String?
    public let override: Bool

    public init(
        name: String,
        aliases: [String] = [],
        description: String? = nil,
        override: Bool = false
    ) {
        self.name = name
        self.aliases = aliases
        self.description = description
        self.override = override
    }
}
