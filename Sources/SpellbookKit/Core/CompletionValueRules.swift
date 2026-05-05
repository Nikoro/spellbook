enum CompletionValueRules {
    static func valueCandidates(
        for param: ParamDefinition,
        kind: CompletionCandidateKind
    ) -> [CompletionCandidate] {
        if param.type == .bool {
            return [
                CompletionCandidate(value: "true", kind: kind),
                CompletionCandidate(value: "false", kind: kind)
            ]
        }
        if !param.values.isEmpty {
            return param.values.map { CompletionCandidate(value: $0, kind: kind) }
        }
        if param.type == .string {
            return [.endOfGrammarFallThrough]
        }
        return []
    }

    static func satisfies(_ param: ParamDefinition, value: String) -> Bool {
        if param.type == .bool { return value == "true" || value == "false" }
        if !param.values.isEmpty { return param.values.contains(value) }
        return true
    }

    static func looksLikeFlag(_ token: String) -> Bool {
        token.hasPrefix("-") && token != "-" && token != "--"
    }
}
