extension ParamDefinition {
    func missingRequiredError(spell: String) -> SpellbookError {
        values.isEmpty
            ? .missingRequiredParam(spell: spell, param: name, flags: flags)
            : .missingRequiredEnumValue(spell: spell, param: name, values: values)
    }
}
