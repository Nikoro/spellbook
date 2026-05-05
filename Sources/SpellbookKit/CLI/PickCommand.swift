public struct PickCommand {
    public init() {}

    public func run(candidates: [String], source: inout DevTTYSource) -> String? {
        guard !candidates.isEmpty else { return nil }
        let outcome = TTYPickerHarness.run(candidates: candidates, source: &source)
        switch outcome {
        case .accepted(let idx):
            return candidates[idx]
        case .cancelled, .pending:
            return nil
        }
    }
}
