struct ArgvScanner {
    private struct EqualsFormDetails {
        let param: ParamDefinition; let flag: String; let value: String
    }

    private let params: [ParamDefinition]
    private let positionals: [ParamDefinition]
    private let flagMap: [String: ParamDefinition]
    private let spell: String
    private let allowPassthrough: Bool
    private let choiceProvider: FiniteChoiceProvider?

    private var values: [String: String] = [:]
    private var passthrough: [String] = []
    private var positionalCursor = 0

    init(
        params: [ParamDefinition],
        spell: String,
        allowPassthrough: Bool,
        choiceProvider: FiniteChoiceProvider? = nil
    ) {
        self.params = params
        self.positionals = params.filter(\.isPositional)
        self.flagMap = Self.buildFlagMap(params)
        self.spell = spell
        self.allowPassthrough = allowPassthrough
        self.choiceProvider = choiceProvider
    }

    var result: ParsedArguments { ParsedArguments(values: values, passthrough: passthrough) }

    mutating func consume(_ argv: [String]) throws {
        var index = 0
        while index < argv.count {
            index = try consumeToken(at: index, argv: argv)
        }
    }

    private mutating func consumeToken(at index: Int, argv: [String]) throws -> Int {
        let token = argv[index]
        if token == "--" {
            return try consumeStopParsingSentinel(at: index, argv: argv)
        }
        if shouldConsumeCurrentPositional(token: token) {
            return try consumePositionalOrPassthrough(token: token, at: index, nextIndex: index + 1)
        }
        if let param = flagMap[token] {
            return try consumeFlag(param: param, at: index, argv: argv)
        }
        if let equalsForm = equalsFormDetails(token) {
            throw SpellbookError.unsupportedEqualsForm(
                spell: spell,
                param: equalsForm.param.name,
                flag: equalsForm.flag,
                value: equalsForm.value
            )
        }
        return try consumePositionalOrPassthrough(token: token, at: index, nextIndex: index + 1)
    }

    private mutating func consumeFlag(
        param: ParamDefinition, at index: Int, argv: [String]
    ) throws -> Int {
        if param.type == .bool {
            return consumeBoolFlag(param: param, at: index, argv: argv)
        }
        guard index + 1 < argv.count else {
            throw SpellbookError.flagMissingValue(spell: spell, param: param.name, flag: argv[index])
        }
        let value = argv[index + 1]
        if shouldRejectFlagLookahead(value, for: param) {
            throw SpellbookError.flagMissingValue(spell: spell, param: param.name, flag: argv[index])
        }
        values[param.name] = value
        return index + 2
    }

    private mutating func consumeBoolFlag(
        param: ParamDefinition, at index: Int, argv: [String]
    ) -> Int {
        let next = index + 1 < argv.count ? argv[index + 1] : nil
        if let next, next == "true" || next == "false" {
            values[param.name] = next
            return index + 2
        }
        values[param.name] = toggleBool(param: param)
        return index + 1
    }

    private func toggleBool(param: ParamDefinition) -> String {
        let base = values[param.name] ?? param.defaultValue ?? param.type.zero
        return base == "true" ? "false" : "true"
    }

    private func shouldConsumeCurrentPositional(token: String) -> Bool {
        positionalCursor < positionals.count
            && isNegativeNumeric(token, for: positionals[positionalCursor])
    }

    private func shouldRejectFlagLookahead(_ value: String, for param: ParamDefinition) -> Bool {
        flagMap[value] != nil && !isNegativeNumeric(value, for: param)
    }
    private func isNegativeNumeric(_ token: String, for param: ParamDefinition) -> Bool {
        guard token.hasPrefix("-") else { return false }
        switch param.type {
        case .int: return Int(token) != nil
        case .double, .number: return Double(token) != nil
        case .string, .bool: return false
        }
    }

    private mutating func consumeStopParsingSentinel(
        at index: Int, argv: [String]
    ) throws -> Int {
        let tail = Array(argv[(index + 1)...])
        guard !tail.isEmpty else { return argv.count }
        guard allowPassthrough else {
            throw SpellbookError.unexpectedArgument(
                spell: spell, value: tail[0],
                index: index + 1, origin: .afterStopParsingSentinel
            )
        }
        passthrough.append(contentsOf: tail)
        return argv.count
    }

    private mutating func consumePositionalOrPassthrough(
        token: String, at index: Int, nextIndex: Int
    ) throws -> Int {
        if positionalCursor < positionals.count {
            values[positionals[positionalCursor].name] = token
            positionalCursor += 1
            return nextIndex
        }
        guard allowPassthrough else {
            throw SpellbookError.unexpectedArgument(
                spell: spell, value: token, index: index, origin: .regular
            )
        }
        passthrough.append(token)
        return nextIndex
    }

    private func equalsFormDetails(_ token: String) -> EqualsFormDetails? {
        guard let eqIdx = token.firstIndex(of: "=") else { return nil }
        let flag = String(token[..<eqIdx])
        guard let param = flagMap[flag] else { return nil }
        return EqualsFormDetails(
            param: param, flag: flag,
            value: String(token[token.index(after: eqIdx)...])
        )
    }

    mutating func fillOptionalDefaults() throws {
        while positionalCursor < positionals.count {
            let param = positionals[positionalCursor]
            if param.isRequired {
                if let value = try EnumChoiceBridge.pick(
                    param: param, spell: spell, provider: choiceProvider
                ) {
                    values[param.name] = value
                    positionalCursor += 1
                    continue
                }
                throw missingRequiredParamError(for: param)
            }
            if let fallback = param.defaultValue {
                values[param.name] = fallback
            }
            positionalCursor += 1
        }
    }

    mutating func checkRequiredNamed() throws {
        for param in params where !param.isPositional && param.isRequired {
            if values[param.name] == nil {
                if let value = try EnumChoiceBridge.pick(
                    param: param, spell: spell, provider: choiceProvider
                ) {
                    values[param.name] = value
                    continue
                }
                throw missingRequiredParamError(for: param)
            }
        }
    }

    private func missingRequiredParamError(for param: ParamDefinition) -> SpellbookError {
        param.missingRequiredError(spell: spell)
    }

    private static func buildFlagMap(_ params: [ParamDefinition]) -> [String: ParamDefinition] {
        var map: [String: ParamDefinition] = [:]
        for param in params where !param.isPositional {
            for flag in param.flags { map[flag] = param }
        }
        return map
    }
}
