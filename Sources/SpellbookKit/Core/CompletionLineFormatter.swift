public enum CompletionLineFormatter {
    public static func format(_ candidates: [CompletionCandidate]) -> [String] {
        candidates.map(formatLine)
    }

    private static func formatLine(_ candidate: CompletionCandidate) -> String {
        if candidate.kind == .fallthrough { return "__SPELLBOOK_FALLTHROUGH__" }
        let needsValue = candidate.needsValueNext ? "1" : "0"
        let description = candidate.description ?? ""
        return [candidate.value, kindLabel(candidate.kind), needsValue, description]
            .joined(separator: "\t")
    }

    private static func kindLabel(_ kind: CompletionCandidateKind) -> String {
        switch kind {
        case .switchOption: return "switchOption"
        case .positionalValue: return "positionalValue"
        case .namedFlag: return "namedFlag"
        case .flagValue: return "flagValue"
        case .runAsIs: return "runAsIs"
        case .fallthrough: return "fallthrough"
        }
    }
}
