import Testing
@testable import SpellbookKit

struct SpellbookParserParamTests {
    private let parser = SpellbookParser()

    @Test func explicitRequired_singlePositionalParam() throws {
        let spell = try #require(try parseFirstSpell(paramFields: [
            MapEntry(key: "required", value: .map([
                MapEntry(key: "name", value: .null)
            ]))
        ]))

        #expect(spell.params == [
            ParamDefinition(name: "name", isRequired: true, isPositional: true)
        ])
    }

    @Test func explicitOptional_keepsDefaultValue() throws {
        let spell = try #require(try parseFirstSpell(paramFields: [
            MapEntry(key: "optional", value: .map([
                MapEntry(key: "greeting", value: .map([
                    MapEntry(key: "default", value: .scalar("hello"))
                ]))
            ]))
        ]))

        let param = try #require(spell.params.first)
        #expect(param.isRequired == false)
        #expect(param.defaultValue == "hello")
    }

    @Test func explicitParams_preserveYAMLOrder_requiredBeforeOptional() throws {
        let spell = try #require(try parseFirstSpell(paramFields: [
            MapEntry(key: "required", value: .map([
                MapEntry(key: "first", value: .null),
                MapEntry(key: "second", value: .null)
            ])),
            MapEntry(key: "optional", value: .map([
                MapEntry(key: "third", value: .null)
            ]))
        ]))

        #expect(spell.params.map(\.name) == ["first", "second", "third"])
        #expect(spell.params.map(\.isRequired) == [true, true, false])
    }

    @Test func explicitParam_typeFieldParsesAsParamType() throws {
        let spell = try #require(try parseFirstSpell(paramFields: [
            MapEntry(key: "required", value: .map([
                MapEntry(key: "count", value: .map([
                    MapEntry(key: "type", value: .scalar("int"))
                ]))
            ]))
        ]))

        #expect(spell.params.first?.type == .int)
    }

    @Test func explicitParam_valuesAcceptFlowSequence() throws {
        let spell = try #require(try parseFirstSpell(paramFields: [
            MapEntry(key: "optional", value: .map([
                MapEntry(key: "platform", value: .map([
                    MapEntry(key: "values", value: .sequence([
                        .scalar("ios"), .scalar("android")
                    ]))
                ]))
            ]))
        ]))

        #expect(spell.params.first?.values == ["ios", "android"])
    }

    @Test func explicitParam_flagsMakeItNamed() throws {
        let spell = try #require(try parseFirstSpell(paramFields: [
            MapEntry(key: "optional", value: .map([
                MapEntry(key: "name", value: .map([
                    MapEntry(key: "flags", value: .scalar("-n, --name"))
                ]))
            ]))
        ]))

        let param = try #require(spell.params.first)
        #expect(param.flags == ["-n", "--name"])
        #expect(param.isPositional == false)
    }

    @Test func inferredMode_paramWithoutDefault_isRequiredPositional() throws {
        let spell = try #require(try parseFirstSpell(paramFields: [
            MapEntry(key: "name", value: .null)
        ]))

        #expect(spell.params == [
            ParamDefinition(name: "name", isRequired: true, isPositional: true)
        ])
    }

    @Test func inferredMode_paramWithDefault_isOptional() throws {
        let spell = try #require(try parseFirstSpell(paramFields: [
            MapEntry(key: "greeting", value: .map([
                MapEntry(key: "default", value: .scalar("hi"))
            ]))
        ]))

        let param = try #require(spell.params.first)
        #expect(param.isRequired == false)
        #expect(param.defaultValue == "hi")
    }

    @Test func inferredMode_paramWithFlags_isNamedAndOptional() throws {
        let spell = try #require(try parseFirstSpell(paramFields: [
            MapEntry(key: "name", value: .map([
                MapEntry(key: "flags", value: .scalar("-n, --name"))
            ]))
        ]))

        let param = try #require(spell.params.first)
        #expect(param.flags == ["-n", "--name"])
        #expect(param.isPositional == false)
        #expect(param.isRequired == false)
    }

    @Test func mixedMode_explicitGroupAndInferredParam_isError() {
        let node: YAMLNode = .map([
            MapEntry(key: "spells", value: .map([
                MapEntry(key: "greet", value: .map([
                    MapEntry(key: "script", value: .scalar("echo")),
                    MapEntry(key: "params", value: .map([
                        MapEntry(key: "required", value: .map([
                            MapEntry(key: "first", value: .null)
                        ])),
                        MapEntry(key: "stray", value: .null)
                    ]))
                ]))
            ]))
        ])

        let error = #expect(throws: SpellbookError.self) {
            try parser.parse(node)
        }
        guard case .mixedParamsMode(let spell) = error else {
            Issue.record("expected mixedParamsMode, got \(error)")
            return
        }
#expect(spell == "greet")
    }

    private func parseFirstSpell(paramFields: [MapEntry]) throws -> SpellDefinition? {
        let node: YAMLNode = .map([
            MapEntry(key: "spells", value: .map([
                MapEntry(key: "greet", value: .map([
                    MapEntry(key: "script", value: .scalar("echo hi")),
                    MapEntry(key: "params", value: .map(paramFields))
                ]))
            ]))
        ])
        return try parser.parse(node).spells.first
    }
}
