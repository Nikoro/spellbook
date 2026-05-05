struct LeafWalkState {
    let spell: SpellDefinition
    var cursor: Int
    let positionals: [ParamDefinition]
    let flagMap: [String: ParamDefinition]
    let namedParams: [ParamDefinition]
    let scriptHasPassthrough: Bool
    var positionalIndex: Int = 0
    var consumedFlags: Set<String> = []
    var flagNeedsValue: ParamDefinition?

    init(spell: SpellDefinition, offset: Int) {
        self.spell = spell
        self.cursor = offset
        self.positionals = spell.params.filter(\.isPositional)
        self.namedParams = spell.params.filter { !$0.isPositional }
        self.flagMap = Self.buildFlagMap(spell.params)
        self.scriptHasPassthrough = ScriptPassthrough.count(in: spell.script ?? "") > 0
    }

    mutating func consume(_ token: String) -> Bool {
        if let pending = flagNeedsValue {
            if !CompletionValueRules.satisfies(pending, value: token) { return false }
            flagNeedsValue = nil
            cursor += 1
            return true
        }
        if let param = flagMap[token] {
            if consumedFlags.contains(param.name) { return false }
            consumedFlags.insert(param.name)
            if param.type != .bool { flagNeedsValue = param }
            cursor += 1
            return true
        }
        if CompletionValueRules.looksLikeFlag(token) { return false }
        if positionalIndex < positionals.count {
            let param = positionals[positionalIndex]
            if !CompletionValueRules.satisfies(param, value: token) { return false }
            positionalIndex += 1
            cursor += 1
            return true
        }
        if scriptHasPassthrough {
            cursor += 1
            return true
        }
        return false
    }

    func candidatesAtCursor(cursorWord: String) -> [CompletionCandidate] {
        if let pending = flagNeedsValue {
            return CompletionValueRules.valueCandidates(for: pending, kind: .flagValue)
        }
        if cursorWord == "-" || cursorWord == "--" {
            return flagCandidates()
        }
        if let required = requiredPositionalBeyondCursor() {
            return CompletionValueRules.valueCandidates(for: required, kind: .positionalValue)
        }
        if let required = firstMissingRequiredNamed() {
            return namedFlagCandidate(required)
        }
        return sectionedCandidates()
    }

    private func requiredPositionalBeyondCursor() -> ParamDefinition? {
        guard positionalIndex < positionals.count else { return nil }
        let param = positionals[positionalIndex]
        return param.isRequired ? param : nil
    }

    private func firstMissingRequiredNamed() -> ParamDefinition? {
        namedParams.first { $0.isRequired && !consumedFlags.contains($0.name) }
    }

    private func namedFlagCandidate(_ param: ParamDefinition) -> [CompletionCandidate] {
        param.flags.prefix(1).map { flag in
            CompletionCandidate(
                value: flag, kind: .namedFlag, description: param.description,
                needsValueNext: param.type != .bool
            )
        }
    }

    private func sectionedCandidates() -> [CompletionCandidate] {
        if scriptHasPassthrough { return [.endOfGrammarFallThrough] }
        var out: [CompletionCandidate] = []
        if let optionalPositional = nextOptionalPositional() {
            out.append(contentsOf: CompletionValueRules.valueCandidates(
                for: optionalPositional, kind: .positionalValue
            ))
        }
        out.append(contentsOf: flagCandidates())
        out.append(CompletionCandidate(value: "", kind: .runAsIs))
        return out
    }

    private func nextOptionalPositional() -> ParamDefinition? {
        guard positionalIndex < positionals.count else { return nil }
        let param = positionals[positionalIndex]
        return param.isRequired ? nil : param
    }

    private func flagCandidates() -> [CompletionCandidate] {
        remainingOptionalFlags().map {
            CompletionCandidate(
                value: $0.flags.first ?? "",
                kind: .namedFlag,
                description: $0.description,
                needsValueNext: $0.type != .bool
            )
        }
    }

    private func remainingOptionalFlags() -> [ParamDefinition] {
        namedParams.filter { !consumedFlags.contains($0.name) }
    }

    private static func buildFlagMap(_ params: [ParamDefinition]) -> [String: ParamDefinition] {
        var map: [String: ParamDefinition] = [:]
        for param in params where !param.isPositional {
            for flag in param.flags { map[flag] = param }
        }
        return map
    }
}
