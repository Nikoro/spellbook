public enum FiniteChoiceOutcome: Equatable, Sendable {
    case selected(Int)
    case cancelled
    case unavailable
}
