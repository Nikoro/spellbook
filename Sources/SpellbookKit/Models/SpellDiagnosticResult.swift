public enum SpellDiagnosticResult: Equatable, Sendable {
    case noState
    case notFoundAnywhere
    case foundInProjects([ProjectMatch])
}
