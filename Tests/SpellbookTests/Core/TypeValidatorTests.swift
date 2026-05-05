import Testing
@testable import SpellbookKit

struct TypeValidatorTests {
    private let validator = TypeValidator()

    @Test func stringParam_acceptsAnyValue() throws {
        let param = ParamDefinition(name: "name")

        let value = try validator.validate(value: "hello world", for: param, spell: "deploy")

        #expect(value == "hello world")
    }

    @Test func boolParam_acceptsTrueAndFalse() throws {
        let param = scalarParam(name: "verbose", type: .bool)

        #expect(try validator.validate(value: "true", for: param, spell: "deploy") == "true")
        #expect(try validator.validate(value: "false", for: param, spell: "deploy") == "false")
    }

    @Test func boolParam_invalidValue_throwsStructuredError() {
        let param = scalarParam(name: "verbose", type: .bool)

        #expect(throws: SpellbookError.invalidParamValue(
                    spell: "deploy",
                    param: "verbose",
                    value: "yes",
                    expected: .bool,
                    validValues: [],
                    example: "true"
                )) {
            try validator.validate(value: "yes", for: param, spell: "deploy")
        }
    }

    @Test func intParam_invalidValue_throwsStructuredError() {
        let param = scalarParam(name: "count", type: .int)

        #expect(throws: SpellbookError.invalidParamValue(
                    spell: "deploy",
                    param: "count",
                    value: "1.5",
                    expected: .int,
                    validValues: [],
                    example: "42"
                )) {
            try validator.validate(value: "1.5", for: param, spell: "deploy")
        }
    }

    @Test func doubleParam_invalidValue_throwsStructuredError() {
        let param = scalarParam(name: "threshold", type: .double)

        #expect(throws: SpellbookError.invalidParamValue(
                    spell: "deploy",
                    param: "threshold",
                    value: "abc",
                    expected: .double,
                    validValues: [],
                    example: "3.14"
                )) {
            try validator.validate(value: "abc", for: param, spell: "deploy")
        }
    }

    @Test func numberParam_acceptsIntegerAndDoubleValues() throws {
        let param = scalarParam(name: "limit", type: .number)

        #expect(try validator.validate(value: "7", for: param, spell: "deploy") == "7")
        #expect(try validator.validate(value: "7.5", for: param, spell: "deploy") == "7.5")
    }

    @Test func stringEnum_matching_isCaseInsensitive_andReturnsCanonicalValue() throws {
        let param = ParamDefinition(
            name: "env",
            schema: ParamSchema(type: .string, values: ["dev", "Prod"])
        )

        let value = try validator.validate(value: "PROD", for: param, spell: "deploy")

        #expect(value == "Prod")
    }

    @Test func numericEnum_matching_usesNumericEquivalence_andReturnsCanonicalValue() throws {
        let param = ParamDefinition(
            name: "limit",
            schema: ParamSchema(type: .number, values: ["1", "2.5"])
        )

        let value = try validator.validate(value: "2.50", for: param, spell: "deploy")

        #expect(value == "2.5")
    }

    @Test func enum_invalidValue_throwsStructuredErrorWithValidValues() {
        let param = ParamDefinition(
            name: "env",
            schema: ParamSchema(type: .string, values: ["dev", "prod"])
        )

        #expect(throws: SpellbookError.invalidParamValue(
                    spell: "deploy",
                    param: "env",
                    value: "stage",
                    expected: .string,
                    validValues: ["dev", "prod"],
                    example: nil
                )) {
            try validator.validate(value: "stage", for: param, spell: "deploy")
        }
    }

    @Test func resolvedValues_validation_usesSameRulesForDefaultsAndArgvValues() {
        let params = [
            ParamDefinition(
                name: "retries",
                shape: ParamShape(isRequired: false, isPositional: true),
                schema: ParamSchema(type: .int, defaultValue: "3")
            ),
            scalarParam(name: "threshold", type: .double)
        ]

        #expect(throws: SpellbookError.invalidParamValue(
                    spell: "deploy",
                    param: "threshold",
                    value: "oops",
                    expected: .double,
                    validValues: [],
                    example: "3.14"
                )) {
            try validator.validate(
                resolvedValues: ["retries": "3", "threshold": "oops"],
                params: params,
                spell: "deploy"
            )
        }
    }

    private func scalarParam(name: String, type: ParamType) -> ParamDefinition {
        ParamDefinition(name: name, schema: ParamSchema(type: type))
    }
}
