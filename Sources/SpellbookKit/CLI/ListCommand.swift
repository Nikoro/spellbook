public struct ListCommand {
    private let resolver: ActivationResolver
    private let verbose: Bool
    private let cacheWriter: ManifestCacheWriterAdapter?

    public init(
        resolver: ActivationResolver,
        verbose: Bool,
        cacheWriter: ManifestCacheWriterAdapter? = nil
    ) {
        self.resolver = resolver
        self.verbose = verbose
        self.cacheWriter = cacheWriter
    }

    public func run(cwd: String) throws -> [String] {
        let result = try resolver.resolve(cwd: cwd)
        let entries = ListResolver.resolve(result.manifest)
        let output = format(entries: entries, source: result.location.source)
        ManifestCacheHook.writeIfPossible(writer: cacheWriter, result: result)
        return output
    }

    private func format(
        entries: [ListEntry],
        source: ManifestLocation.Source
    ) -> [String] {
        if entries.isEmpty { return ["No spells defined."] }
        var lines: [String] = []
        for entry in entries {
            var line = entry.name
            if entry.override {
                line += "  [override]"
            }
            if !entry.aliases.isEmpty {
                line += "  (" + entry.aliases.joined(separator: ", ") + ")"
            }
            lines.append(line)
            if verbose {
                if let desc = entry.description {
                    lines.append("  \(desc)")
                }
            }
        }
        return lines
    }
}
