enum ActivationSummaryRenderer {
    static func renderChanges(_ changes: [DiffEntry]) -> [String] {
        guard !changes.isEmpty else { return [] }
        return changes.map { entry in
            switch entry.kind {
            case .added: return "  + \(entry.name)"
            case .changed: return "  ~ \(entry.name)"
            case .removed: return "  - \(entry.name)"
            }
        }
    }
}
