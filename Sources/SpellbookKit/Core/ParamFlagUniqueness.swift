enum ParamFlagUniqueness {
    static func check(_ params: [ParamDefinition], spell: String) -> [SpellbookError] {
        let flags = params.flatMap(\.flags)
        return DuplicateTokens.find(flags).map { .duplicateParamFlag(spell: spell, flag: $0) }
    }
}
