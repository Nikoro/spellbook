@testable import SpellbookKit

final class MockChoiceProvider: FiniteChoiceProvider {
    var outcome: FiniteChoiceOutcome = .unavailable
    private(set) var chosenOptions: [String] = []
    private(set) var chosenPrompt: String?
    private(set) var callCount = 0

    func choose(
        options: [String],
        prompt: String
    ) throws -> FiniteChoiceOutcome {
        chosenOptions = options
        chosenPrompt = prompt
        callCount += 1
        return outcome
    }
}
