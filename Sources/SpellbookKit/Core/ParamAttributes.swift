struct ParamAttributes {
    var description: String?
    var flags: [String] = []
    var defaultValue: String?
    var type: ParamType = .string
    var values: [String] = []

    var schema: ParamSchema {
        ParamSchema(type: type, values: values, defaultValue: defaultValue)
    }

    func shape(isRequired: Bool) -> ParamShape {
        ParamShape(isRequired: isRequired, isPositional: flags.isEmpty, flags: flags)
    }

    var inferredIsRequired: Bool {
        flags.isEmpty && defaultValue == nil
    }
}
