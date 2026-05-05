@testable import SpellbookKit

enum Phase3E2EFixtures {
    static func manifest() -> SpellbookManifest {
        let envPositional = ParamDefinition(
            name: "env",
            shape: ParamShape(isRequired: true, isPositional: true),
            schema: ParamSchema(type: .string, values: ["staging", "prod", "dev"])
        )
        let sbdeploy = SpellDefinition(
            identity: SpellIdentity(name: "sbdeploy"),
            body: SpellBody(script: "deploy {{env}}", params: [envPositional])
        )
        let envFlag = ParamDefinition(
            name: "env",
            shape: ParamShape(isRequired: false, isPositional: false, flags: ["--env"]),
            schema: ParamSchema(type: .string, values: ["staging", "prod"])
        )
        let sbtest = SpellDefinition(
            identity: SpellIdentity(name: "sbtest"),
            body: SpellBody(script: "pytest", params: [envFlag])
        )
        let hello = SpellDefinition(name: "hello", script: "echo hi")
        return SpellbookManifest(spells: [sbdeploy, sbtest, hello])
    }

    static func candidateValues(
        wrapper: String, tokens: [String], cword: Int
    ) -> [String] {
        let args = CompleteCommandArgs(wrapper: wrapper, cword: cword, tokens: tokens)
        return CompleteOrchestrator.compute(args: args, manifest: manifest())
            .map { String($0.split(separator: "\t", omittingEmptySubsequences: false)[0]) }
    }

    static func lines(
        wrapper: String, tokens: [String], cword: Int
    ) -> [String] {
        let args = CompleteCommandArgs(wrapper: wrapper, cword: cword, tokens: tokens)
        return CompleteOrchestrator.compute(args: args, manifest: manifest())
    }
}
