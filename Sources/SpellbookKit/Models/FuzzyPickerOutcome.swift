public enum FuzzyPickerOutcome: Equatable, Sendable {
    case pending
    case accepted(Int)
    case cancelled
}
