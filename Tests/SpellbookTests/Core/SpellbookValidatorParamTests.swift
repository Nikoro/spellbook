import Testing
@testable import SpellbookKit

struct SpellbookValidatorParamTests {
    private let validator = SpellbookValidator()

    @Test func paramName_withHyphen_isError() {
        assertParamName("dry-run", produces: .invalidParamName(spell: "build", name: "dry-run"))
    }

    @Test func paramName_withLeadingDigit_isError() {
        assertParamName("1st", produces: .invalidParamName(spell: "build", name: "1st"))
    }

    @Test func paramName_withLeadingUnderscore_isValid() {
        assertParamName("_internal", produces: nil)
    }

    @Test func paramName_snakeCase_isValid() {
        assertParamName("dry_run", produces: nil)
    }

    @Test func overrideSpell_paramNameMatchesSpellName_isError() {
        let spell = SpellDefinition(
            identity: SpellIdentity(name: "ls"),
            body: SpellBody(
                script: "ls --color",
                params: [ParamDefinition(name: "ls")]
            ),
            runtime: SpellRuntime(override: true)
        )
        #expect(
            validator.validate(SpellbookManifest(spells: [spell])) ==
            [.paramShadowsOverriddenSpell(spell: "ls", param: "ls")]
        )
    }

    @Test func nonOverrideSpell_paramNameMatchesSpellName_isValid() {
        let spell = SpellDefinition(
            identity: SpellIdentity(name: "ls"),
            body: SpellBody(
                script: "ls --color",
                params: [ParamDefinition(name: "ls")]
            )
        )
        #expect(validator.validate(SpellbookManifest(spells: [spell])) == [])
    }

    @Test func requiredParam_withDefault_isError() {
        let spell = SpellDefinition(
            identity: SpellIdentity(name: "build"),
            body: SpellBody(
                script: "./build",
                params: [ParamDefinition(
                    name: "target",
                    shape: ParamShape(isRequired: true),
                    schema: ParamSchema(defaultValue: "./out")
                )]
            )
        )
        #expect(
            validator.validate(SpellbookManifest(spells: [spell])) ==
            [.requiredParamHasDefault(spell: "build", param: "target")]
        )
    }

    @Test func params_duplicateFlag_acrossParams_isError() {
        let spell = SpellDefinition(
            identity: SpellIdentity(name: "build"),
            body: SpellBody(
                script: "./build",
                params: [
                    ParamDefinition(
                        name: "verbose",
                        shape: ParamShape(isRequired: false, isPositional: false, flags: ["-v"])
                    ),
                    ParamDefinition(
                        name: "version",
                        shape: ParamShape(isRequired: false, isPositional: false, flags: ["-v"])
                    )
                ]
            )
        )
        #expect(
            validator.validate(SpellbookManifest(spells: [spell])) ==
            [.duplicateParamFlag(spell: "build", flag: "-v")]
        )
    }

    private func assertParamName(
        _ name: String,
        produces expected: SpellbookError?,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        let spell = SpellDefinition(
            identity: SpellIdentity(name: "build"),
            body: SpellBody(
                script: "./build",
                params: [ParamDefinition(name: name)]
            )
        )
        let errors = validator.validate(SpellbookManifest(spells: [spell]))
        if let expected {
            #expect(errors == [expected], sourceLocation: sourceLocation)
        } else {
            #expect(errors == [], sourceLocation: sourceLocation)
        }
    }
}
