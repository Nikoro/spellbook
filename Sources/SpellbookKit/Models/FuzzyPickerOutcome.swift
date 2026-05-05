public enum FuzzyPickerOutcome: Equatable, Sendable {
    case pending
    case accepted(Int) // index into the original candidates array
    case cancelled
}
