public enum CompletionCandidateKind: Equatable, Sendable {
    case switchOption
    case positionalValue
    case namedFlag
    case flagValue
    case runAsIs
    case `fallthrough`
}
