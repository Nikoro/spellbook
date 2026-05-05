import Foundation

public struct ActivationCommand {
    private let resolver: ActivationResolver
    private let wrapperGenerator: WrapperGenerator
    private let stateStore: StateStore
    private let manifestContent: ManifestContentReader
    private let cacheWriter: ManifestCacheWriterAdapter?
    private let fileLock: FileLock?

    public init(
        resolver: ActivationResolver,
        wrapperGenerator: WrapperGenerator,
        stateStore: StateStore,
        manifestContent: ManifestContentReader,
        cacheWriter: ManifestCacheWriterAdapter? = nil,
        fileLock: FileLock? = nil
    ) {
        self.resolver = resolver
        self.wrapperGenerator = wrapperGenerator
        self.stateStore = stateStore
        self.manifestContent = manifestContent
        self.cacheWriter = cacheWriter
        self.fileLock = fileLock
    }

    public func activate(cwd: String) throws -> ActivationSummary {
        let result = try resolver.resolve(cwd: cwd)
        let changes = DiffDetector.detect(
            fresh: result,
            state: (try? stateStore.read())?.projects[parentDirectory(of: result.location.path)]
        )
        let summary = try writePhase(result: result, changes: changes)
        ManifestCacheHook.writeIfPossible(writer: cacheWriter, result: result)
        return summary
    }

    private func writePhase(
        result: ActivationResult,
        changes: [DiffEntry]
    ) throws -> ActivationSummary {
        let body: () throws -> ActivationSummary = {
            let wrapperPaths = try wrapperGenerator.generate(manifest: result.manifest)
            let snapshot = buildSnapshot(result: result, wrapperPaths: wrapperPaths)
            try stateStore.write(snapshot)
            return ActivationSummary(
                source: result.location.source,
                manifestPath: result.location.path,
                spellCount: result.manifest.spells.count,
                wrapperCount: wrapperPaths.count,
                changes: changes
            )
        }
        if let fileLock {
            return try fileLock.withExclusiveLock(body)
        }
        return try body()
    }

    private func buildSnapshot(
        result: ActivationResult,
        wrapperPaths: [String: String]
    ) -> StateSnapshot {
        let raw = (try? manifestContent.readContent(at: result.location.path)) ?? ""
        let manifestHash = ManifestHasher.hashManifest(raw)
        let projectKey = parentDirectory(of: result.location.path)
        var spellStates: [String: SpellState] = [:]
        for spell in result.manifest.spells {
            let origin = originPath(for: spell, result: result)
            spellStates[spell.name] = SpellState(
                hash: ManifestHasher.hashSpell(spell),
                wrapper: wrapperPaths[spell.name] ?? "",
                origin: origin
            )
        }
        let projectState = ProjectState(
            spellsYamlHash: manifestHash,
            chain: result.chain,
            spells: spellStates
        )
        let existing = (try? stateStore.read()) ?? StateSnapshot(updatedAt: "")
        var projects = existing.projects
        projects[projectKey] = projectState
        return StateSnapshot(
            updatedAt: currentTimestamp(),
            projects: projects
        )
    }

    private func originPath(
        for spell: SpellDefinition,
        result: ActivationResult
    ) -> String {
        result.spellOrigins[spell.name]
            ?? result.chain.last
            ?? result.location.path
    }

    private func parentDirectory(of path: String) -> String {
        if path.isEmpty { return path }
        let trimmed = path.hasSuffix("/") ? String(path.dropLast()) : path
        guard let slash = trimmed.lastIndex(of: "/") else { return trimmed }
        if slash == trimmed.startIndex { return "/" }
        return String(trimmed[trimmed.startIndex..<slash])
    }

    private func currentTimestamp() -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: Date())
    }
}
