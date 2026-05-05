public protocol FiniteChoiceProvider {
    func choose(
        options: [String],
        prompt: String
    ) throws -> FiniteChoiceOutcome
}
