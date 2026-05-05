public protocol ManifestLoader {
    func load(extends: String, from basePath: String) throws -> LoadedManifest
}
