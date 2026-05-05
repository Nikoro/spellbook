public struct TypeValidator {
    public init() {}

    public func validate(
        value: String,
        for param: ParamDefinition,
        spell: String
    ) throws -> String {
        guard isValid(value, for: param.type) else {
            throw SpellbookError.invalidParamValue(
                spell: spell,
                param: param.name,
                value: value,
                expected: param.type,
                validValues: [],
                example: example(for: param.type)
            )
        }
        if let canonical = canonicalEnumValue(matching: value, for: param) {
            return canonical
        }
        if !param.values.isEmpty {
            throw SpellbookError.invalidParamValue(
                spell: spell,
                param: param.name,
                value: value,
                expected: param.type,
                validValues: param.values,
                example: nil
            )
        }
        return value
    }

    public func validate(
        resolvedValues: [String: String],
        params: [ParamDefinition],
        spell: String
    ) throws -> [String: String] {
        var validated = resolvedValues
        for param in params {
            guard let value = validated[param.name] else { continue }
            validated[param.name] = try validate(value: value, for: param, spell: spell)
        }
        return validated
    }

    private func isValid(_ value: String, for type: ParamType) -> Bool {
        switch type {
        case .string:
            return true
        case .bool:
            return value == "true" || value == "false"
        case .int:
            return Int(value) != nil
        case .double, .number:
            guard let parsed = Double(value) else { return false }
            return parsed.isFinite
        }
    }

    private func example(for type: ParamType) -> String? {
        switch type {
        case .string:
            return nil
        case .bool:
            return "true"
        case .int:
            return "42"
        case .double:
            return "3.14"
        case .number:
            return "42"
        }
    }

    private func canonicalEnumValue(matching value: String, for param: ParamDefinition) -> String? {
        guard !param.values.isEmpty else { return nil }
        switch param.type {
        case .string:
            let candidate = value.lowercased()
            return param.values.first { $0.lowercased() == candidate }
        case .int, .double, .number:
            guard let numericValue = finiteDouble(value) else { return nil }
            return param.values.first { candidate in
                guard let numericCandidate = finiteDouble(candidate) else { return false }
                return numericCandidate == numericValue
            }
        case .bool:
            return param.values.first { $0 == value }
        }
    }

    private func finiteDouble(_ value: String) -> Double? {
        guard let parsed = Double(value), parsed.isFinite else { return nil }
        return parsed
    }
}
