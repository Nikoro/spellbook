public struct DiffCommand {
    private let resolver: ActivationResolver
    private let stateStore: StateStore
    private let cacheWriter: ManifestCacheWriterAdapter?

    public init(
        resolver: ActivationResolver,
        stateStore: StateStore,
        cacheWriter: ManifestCacheWriterAdapter? = nil
    ) {
        self.resolver = resolver
        self.stateStore = stateStore
        self.cacheWriter = cacheWriter
    }

    public func run(cwd: String) throws -> [String] {
        let fresh = try resolver.resolve(cwd: cwd)
        let snapshot = try? stateStore.read()
        let projectKey = DiffProjectKey.parent(of: fresh.location.path)
        let project = snapshot?.projects[projectKey]
        let entries = DiffDetector.detect(fresh: fresh, state: project)
        ManifestCacheHook.writeIfPossible(writer: cacheWriter, result: fresh)
        if entries.isEmpty {
            return ["No changes since last activation."]
        }
        return entries.map(Self.format)
    }

    private static func format(_ entry: DiffEntry) -> String {
        let marker: String
        switch entry.kind {
        case .added: marker = "+"
        case .changed: marker = "~"
        case .removed: marker = "-"
        }
        if let origin = entry.origin, !origin.isEmpty {
            return "\(marker) \(entry.name)  (\(origin))"
        }
        return "\(marker) \(entry.name)"
    }
}
