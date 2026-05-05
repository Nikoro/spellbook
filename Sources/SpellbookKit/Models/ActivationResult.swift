public struct ActivationResult: Equatable, Sendable {
    public let manifest: SpellbookManifest
    public let location: ManifestLocation
    public let chain: [String]
    public let spellOrigins: [String: String]

    public init(
        manifest: SpellbookManifest,
        location: ManifestLocation,
        chain: [String],
        spellOrigins: [String: String] = [:]
    ) {
        self.manifest = manifest
        self.location = location
        self.chain = chain
        self.spellOrigins = spellOrigins
    }
}
