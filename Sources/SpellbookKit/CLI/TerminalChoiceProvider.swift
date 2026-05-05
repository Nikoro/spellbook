public struct TerminalChoiceProvider: FiniteChoiceProvider {
    private let terminal: TerminalProtocol

    public init(terminal: TerminalProtocol) {
        self.terminal = terminal
    }

    public func choose(
        options: [String],
        prompt: String
    ) throws -> FiniteChoiceOutcome {
        let result = try FiniteChoicePicker.pick(
            options: options,
            prompt: prompt,
            terminal: terminal
        )
        switch result {
        case .selected(let index): return .selected(index)
        case .cancelled: return .cancelled
        case .unavailable: return .unavailable
        }
    }
}
