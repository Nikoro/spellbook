public struct ParamResolver {
    private let typeValidator = TypeValidator()
    private let choiceProvider: FiniteChoiceProvider?

    public init(choiceProvider: FiniteChoiceProvider? = nil) {
        self.choiceProvider = choiceProvider
    }

    public func resolve(
        argv: [String],
        params: [ParamDefinition],
        spell: String,
        passthrough: Bool
    ) throws -> ParsedArguments {
        var scanner = ArgvScanner(
            params: params, spell: spell,
            allowPassthrough: passthrough,
            choiceProvider: choiceProvider
        )
        try scanner.consume(argv)
        try scanner.fillOptionalDefaults()
        try scanner.checkRequiredNamed()
        let result = scanner.result
        let validatedValues = try typeValidator.validate(
            resolvedValues: result.values,
            params: params,
            spell: spell
        )
        return ParsedArguments(values: validatedValues, passthrough: result.passthrough)
    }
}
