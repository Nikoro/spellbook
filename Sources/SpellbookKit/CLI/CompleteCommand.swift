public struct CompleteCommand {
    private let resolver: ActivationResolver
    private let cacheReader: ManifestCacheReaderAdapter?
    private let cacheWriter: ManifestCacheWriterAdapter?

    public init(
        resolver: ActivationResolver,
        cacheReader: ManifestCacheReaderAdapter? = nil,
        cacheWriter: ManifestCacheWriterAdapter? = nil
    ) {
        self.resolver = resolver
        self.cacheReader = cacheReader
        self.cacheWriter = cacheWriter
    }

    public func run(arguments: [String], cwd: String) -> [String] {
        guard let args = try? CompleteCommandArgs.parse(arguments) else { return [] }
        guard let manifest = loadManifest(cwd: cwd) else { return [] }
        return CompleteOrchestrator.compute(args: args, manifest: manifest)
    }

    private func loadManifest(cwd: String) -> SpellbookManifest? {
        if let fresh = try? resolver.resolve(cwd: cwd) {
            ManifestCacheHook.writeIfPossible(writer: cacheWriter, result: fresh)
            return fresh.manifest
        }
        if let reader = cacheReader,
           let stale = staleFallback(reader: reader, cwd: cwd) {
            return stale
        }
        return nil
    }

    private func staleFallback(
        reader: ManifestCacheReaderAdapter,
        cwd: String
    ) -> SpellbookManifest? {
        // Without a successful resolve we cannot compute the project path —
        // best-effort: inspect common manifest names in cwd.
        let candidates = [cwd + "/spells.yaml", cwd + "/.spells.yaml"]
        for path in candidates {
            if let decoded = reader.readAnyCache(projectRootManifestPath: path) {
                return decoded.merged
            }
        }
        return nil
    }
}
