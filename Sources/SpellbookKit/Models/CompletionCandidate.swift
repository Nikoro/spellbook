public struct CompletionCandidate: Equatable, Sendable {
    public let value: String
    public let kind: CompletionCandidateKind
    public let description: String?
    public let needsValueNext: Bool

    public init(
        value: String,
        kind: CompletionCandidateKind,
        description: String? = nil,
        needsValueNext: Bool = false
    ) {
        self.value = value
        self.kind = kind
        self.description = description
        self.needsValueNext = needsValueNext
    }

    public static let endOfGrammarFallThrough = CompletionCandidate(
        value: "__SPELLBOOK_FALLTHROUGH__",
        kind: .fallthrough
    )
}
