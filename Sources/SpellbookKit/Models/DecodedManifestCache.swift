public struct DecodedManifestCache: Equatable, Sendable {
    public let merged: SpellbookManifest
    public let extendsChain: [String]
    public let formatVersion: UInt16

    public init(merged: SpellbookManifest, extendsChain: [String], formatVersion: UInt16) {
        self.merged = merged
        self.extendsChain = extendsChain
        self.formatVersion = formatVersion
    }
}
