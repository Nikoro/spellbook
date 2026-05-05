import Foundation

public struct CleanCommand {
    private let resolver: ActivationResolver
    private let stateStore: StateStore
    private let wrapperWriter: WrapperWriter
    private let cacheWriter: ManifestCacheWriterAdapter?

    public init(
        resolver: ActivationResolver,
        stateStore: StateStore,
        wrapperWriter: WrapperWriter,
        cacheWriter: ManifestCacheWriterAdapter? = nil
    ) {
        self.resolver = resolver
        self.stateStore = stateStore
        self.wrapperWriter = wrapperWriter
        self.cacheWriter = cacheWriter
    }

    public func run(arguments: [String], cwd: String) throws -> [String] {
        let scope = try Self.parseScope(arguments)
        let (project, projectKey) = try currentProject(cwd: cwd, scope: scope)
        let resolved = try? resolver.resolve(cwd: cwd)
        let plan = CleanResolver.plan(
            scope: scope, manifest: resolved?.manifest, project: project
        )
        try execute(plan: plan, projectKey: projectKey)
        if let resolved = resolved {
            ManifestCacheHook.writeIfPossible(writer: cacheWriter, result: resolved)
        }
        return summary(plan: plan, scope: scope)
    }

    static func parseScope(_ arguments: [String]) throws -> CleanResolver.Scope {
        if arguments.contains("--all") { return .all }
        if arguments.contains("--orphans") { return .orphans }
        guard let name = arguments.first, !name.hasPrefix("--") else {
            throw SpellbookError.cleanRequiresArgument
        }
        return .named(name)
    }

    private func currentProject(
        cwd: String, scope: CleanResolver.Scope
    ) throws -> (ProjectState?, String) {
        let snapshot = try? stateStore.read()
        if let projectKey = projectKey(from: snapshot, cwd: cwd) {
            return (snapshot?.projects[projectKey], projectKey)
        }
        return (nil, cwd)
    }

    private func projectKey(from snapshot: StateSnapshot?, cwd: String) -> String? {
        snapshot?.projects.keys.first { cwd.hasPrefix($0) } ?? snapshot?.projects.keys.first
    }

    private func execute(plan: CleanPlan, projectKey: String) throws {
        for wrapper in plan.wrappersToRemove {
            try? wrapperWriter.removeWrapper(at: wrapper)
        }
        guard var snapshot = try? stateStore.read() else { return }
        var projects = snapshot.projects
        if plan.clearProject {
            projects.removeValue(forKey: projectKey)
        } else if var project = projects[projectKey] {
            var spells = project.spells
            for name in plan.stateNamesToForget { spells.removeValue(forKey: name) }
            project = ProjectState(
                spellsYamlHash: project.spellsYamlHash,
                chain: project.chain,
                spells: spells
            )
            projects[projectKey] = project
        }
        snapshot = StateSnapshot(
            version: snapshot.version,
            updatedAt: ISO8601DateFormatter().string(from: Date()),
            projects: projects
        )
        try stateStore.write(snapshot)
    }

    private func summary(plan: CleanPlan, scope: CleanResolver.Scope) -> [String] {
        if plan.wrappersToRemove.isEmpty && plan.stateNamesToForget.isEmpty && !plan.clearProject {
            return ["Nothing to clean."]
        }
        let removed = plan.stateNamesToForget.joined(separator: ", ")
        switch scope {
        case .all:
            return ["Cleaned \(plan.wrappersToRemove.count) wrappers and cleared project state."]
        case .orphans:
            return ["Cleaned \(plan.wrappersToRemove.count) orphan wrappers: \(removed)"]
        case .named(let name):
            return ["Cleaned `\(name)` (\(plan.wrappersToRemove.count) wrappers)."]
        }
    }
}
