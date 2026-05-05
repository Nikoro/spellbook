public enum StaleDiagnostic {
    public static func diagnose(
        spellName: String,
        state: StateSnapshot?
    ) -> SpellDiagnosticResult {
        guard let state = state else { return .noState }
        var matches: [ProjectMatch] = []
        for (projectPath, project) in state.projects {
            if let spellState = project.spells[spellName] {
                matches.append(ProjectMatch(
                    projectPath: projectPath,
                    originManifest: spellState.origin
                ))
            }
        }
        if matches.isEmpty { return .notFoundAnywhere }
        return .foundInProjects(matches.sorted { $0.projectPath < $1.projectPath })
    }
}
