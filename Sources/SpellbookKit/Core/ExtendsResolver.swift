public struct ExtendsResolver {
    public struct Resolution {
        public let manifest: SpellbookManifest
        public let chain: [String]
        public let spellOrigins: [String: String]
    }

    private let loader: ManifestLoader

    public init(loader: ManifestLoader) {
        self.loader = loader
    }

    public func resolve(_ manifest: SpellbookManifest, basePath: String) throws -> SpellbookManifest {
        try resolveWithChain(manifest, basePath: basePath).manifest
    }

    public func resolveWithChain(
        _ manifest: SpellbookManifest,
        basePath: String
    ) throws -> Resolution {
        try resolve(manifest, canonicalPath: basePath, visited: [basePath])
    }

    private func resolve(
        _ manifest: SpellbookManifest,
        canonicalPath: String,
        visited: Set<String>
    ) throws -> Resolution {
        let localOrigins = Dictionary(
            uniqueKeysWithValues: manifest.spells.map { ($0.name, canonicalPath) }
        )
        guard let extends = manifest.extends else {
            return Resolution(
                manifest: manifest,
                chain: [canonicalPath],
                spellOrigins: localOrigins
            )
        }
        let loaded = try loader.load(extends: extends, from: canonicalPath)
        if visited.contains(loaded.canonicalPath) {
            throw SpellbookError.extendsCycle(path: loaded.canonicalPath)
        }
        let resolvedParent = try resolve(
            loaded.manifest,
            canonicalPath: loaded.canonicalPath,
            visited: visited.union([loaded.canonicalPath])
        )
        let mergedManifest = ExtendsMerge.closerWins(
            child: manifest,
            parent: resolvedParent.manifest
        )
        var mergedOrigins = resolvedParent.spellOrigins
        mergedOrigins.merge(localOrigins) { _, child in child }
        return Resolution(
            manifest: mergedManifest,
            chain: resolvedParent.chain + [canonicalPath],
            spellOrigins: mergedOrigins
        )
    }
}
