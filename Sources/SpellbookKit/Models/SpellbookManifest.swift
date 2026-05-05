public struct SpellbookManifest: Equatable, Sendable {
    public let version: Int
    public let extends: String?
    public let spells: [SpellDefinition]

    public init(version: Int = 1, extends: String? = nil, spells: [SpellDefinition]) {
        self.version = version
        self.extends = extends
        self.spells = spells
    }
}
