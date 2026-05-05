enum EnumChoiceBridge {
    static func pick(
        param: ParamDefinition,
        spell: String,
        provider: FiniteChoiceProvider?
    ) throws -> String? {
        guard !param.values.isEmpty, let provider else { return nil }
        let outcome = try provider.choose(
            options: param.values, prompt: param.name
        )
        switch outcome {
        case .selected(let idx): return param.values[idx]
        case .cancelled: throw SpellbookError.selectionCancelled(spell: spell)
        case .unavailable: return nil
        }
    }
}
