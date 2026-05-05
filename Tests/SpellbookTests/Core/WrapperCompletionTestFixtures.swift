@testable import SpellbookKit

enum WrapperCompletionTestFixtures {
    static func spell(
        _ name: String,
        params: [ParamDefinition] = [],
        switchBranches: SwitchDefinition? = nil,
        script: String? = "echo hi"
    ) -> SpellDefinition {
        SpellDefinition(
            identity: SpellIdentity(name: name),
            body: SpellBody(script: script, params: params, switchBranches: switchBranches)
        )
    }

    static func manifest(_ spells: [SpellDefinition]) -> SpellbookManifest {
        SpellbookManifest(spells: spells)
    }

    static func resolve(
        _ manifest: SpellbookManifest,
        wrapper: String,
        tokens: [String],
        cword: Int
    ) -> [CompletionCandidate] {
        WrapperCompletionResolver.resolveCompletion(
            tokens: tokens, cword: cword, manifest: manifest, wrapper: wrapper
        )
    }

    static func requiredEnumParam(
        name: String, values: [String]
    ) -> ParamDefinition {
        ParamDefinition(
            name: name,
            shape: ParamShape(isRequired: true, isPositional: true),
            schema: ParamSchema(type: .string, values: values)
        )
    }

    static func optionalFlagBool(name: String, flags: [String]) -> ParamDefinition {
        ParamDefinition(
            name: name,
            shape: ParamShape(isRequired: false, isPositional: false, flags: flags),
            schema: ParamSchema(type: .bool)
        )
    }

    static func flagWithEnumValue(
        name: String, flags: [String], values: [String]
    ) -> ParamDefinition {
        ParamDefinition(
            name: name,
            shape: ParamShape(isRequired: false, isPositional: false, flags: flags),
            schema: ParamSchema(type: .string, values: values)
        )
    }
}
