public enum CleanResolver {
    public enum Scope: Equatable {
        case named(String)
        case orphans
        case all
    }

    public static func plan(
        scope: Scope,
        manifest: SpellbookManifest?,
        project: ProjectState?
    ) -> CleanPlan {
        switch scope {
        case .all: return planAll(project: project)
        case .named(let name): return planNamed(name, project: project)
        case .orphans: return planOrphans(manifest: manifest, project: project)
        }
    }

    private static func planAll(project: ProjectState?) -> CleanPlan {
        guard let project = project else {
            return CleanPlan(wrappersToRemove: [], stateNamesToForget: [], clearProject: true)
        }
        let wrappers = project.spells.values.map(\.wrapper).filter { !$0.isEmpty }
        let names = Array(project.spells.keys)
        return CleanPlan(
            wrappersToRemove: wrappers.sorted(),
            stateNamesToForget: names.sorted(),
            clearProject: true
        )
    }

    private static func planNamed(_ name: String, project: ProjectState?) -> CleanPlan {
        guard let stored = project?.spells[name] else {
            return CleanPlan(wrappersToRemove: [], stateNamesToForget: [])
        }
        let wrapper = stored.wrapper.isEmpty ? [] : [stored.wrapper]
        return CleanPlan(wrappersToRemove: wrapper, stateNamesToForget: [name])
    }

    private static func planOrphans(
        manifest: SpellbookManifest?,
        project: ProjectState?
    ) -> CleanPlan {
        guard let project = project else {
            return CleanPlan(wrappersToRemove: [], stateNamesToForget: [])
        }
        let currentNames = Set(manifest?.spells.map(\.name) ?? [])
        let orphans = project.spells.filter { currentNames.contains($0.key) == false }
        let wrappers = orphans.values.map(\.wrapper).filter { !$0.isEmpty }
        return CleanPlan(
            wrappersToRemove: wrappers.sorted(),
            stateNamesToForget: Array(orphans.keys).sorted()
        )
    }
}
