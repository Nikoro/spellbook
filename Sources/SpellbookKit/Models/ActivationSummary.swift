public struct ActivationSummary: Equatable, Sendable {
    public let source: ManifestLocation.Source
    public let manifestPath: String
    public let spellCount: Int
    public let wrapperCount: Int
    public let changes: [DiffEntry]

    public init(
        source: ManifestLocation.Source,
        manifestPath: String,
        spellCount: Int,
        wrapperCount: Int,
        changes: [DiffEntry] = []
    ) {
        self.source = source
        self.manifestPath = manifestPath
        self.spellCount = spellCount
        self.wrapperCount = wrapperCount
        self.changes = changes
    }
}
