public protocol ManifestReader {
    func read(at path: String) throws -> SpellbookManifest
}
