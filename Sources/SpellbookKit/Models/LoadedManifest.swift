public struct LoadedManifest: Equatable, Sendable {
    public let manifest: SpellbookManifest
    public let canonicalPath: String

    public init(manifest: SpellbookManifest, canonicalPath: String) {
        self.manifest = manifest
        self.canonicalPath = canonicalPath
    }
}
