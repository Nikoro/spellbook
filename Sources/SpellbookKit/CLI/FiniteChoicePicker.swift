public enum FiniteChoicePicker {

    public enum Result: Equatable {
        case selected(Int)
        case cancelled
        case unavailable
    }

    public static func pick(
        options: [String],
        prompt: String,
        terminal: TerminalProtocol
    ) throws -> Result {
        guard !options.isEmpty else { return .cancelled }
        let caps = terminal.capabilities
        guard caps.isTTY else { return .unavailable }
        if caps.supportsRawMode {
            return try map(InteractivePicker.pick(
                options: options,
                prompt: prompt,
                terminal: terminal
            ))
        }
        return map(NumberedPicker.pick(
            options: options,
            prompt: prompt,
            terminal: terminal
        ))
    }

    private static func map(
        _ result: InteractivePicker.Result
    ) -> Result {
        switch result {
        case .selected(let idx): return .selected(idx)
        case .cancelled: return .cancelled
        }
    }
}
