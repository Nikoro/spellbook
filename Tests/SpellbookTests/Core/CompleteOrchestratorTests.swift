import Testing
@testable import SpellbookKit

struct CompleteOrchestratorTests {

    private func manifest(_ spells: [SpellDefinition]) -> SpellbookManifest {
        SpellbookManifest(spells: spells)
    }

    @Test func emitsFullCandidateSet_whenCursorWordEmpty() {
        let param = ParamDefinition(
            name: "env",
            shape: ParamShape(isRequired: true, isPositional: true),
            schema: ParamSchema(type: .string, values: ["staging", "prod", "dev"])
        )
        let book = manifest([SpellDefinition(
            identity: SpellIdentity(name: "sbdeploy"),
            body: SpellBody(script: "echo", params: [param])
        )])
        let args = CompleteCommandArgs(
            wrapper: "sbdeploy", cword: 1, tokens: ["sbdeploy", ""]
        )
        let lines = CompleteOrchestrator.compute(args: args, manifest: book)
        let values = lines.map { String($0.split(separator: "\t")[0]) }
        #expect(values == ["staging", "prod", "dev"])
    }

    @Test func fuzzyFilters_whenCursorWordNonEmpty() {
        let param = ParamDefinition(
            name: "env",
            shape: ParamShape(isRequired: true, isPositional: true),
            schema: ParamSchema(type: .string, values: ["staging", "prod", "dev"])
        )
        let book = manifest([SpellDefinition(
            identity: SpellIdentity(name: "sbdeploy"),
            body: SpellBody(script: "echo", params: [param])
        )])
        let args = CompleteCommandArgs(
            wrapper: "sbdeploy", cword: 1, tokens: ["sbdeploy", "st"]
        )
        let lines = CompleteOrchestrator.compute(args: args, manifest: book)
        // `st` fuzzy-matches "staging" (prefix).
        #expect(lines.first.flatMap { $0.split(separator: "\t").first.map(String.init) }
                == "staging")
    }

    @Test func unknownWrapper_emitsNoLines() {
        let book = manifest([SpellDefinition(name: "hello")])
        let args = CompleteCommandArgs(
            wrapper: "unknown", cword: 0, tokens: ["unknown"]
        )
        let lines = CompleteOrchestrator.compute(args: args, manifest: book)
        #expect(lines.isEmpty)
    }

    @Test func fallthroughSentinel_isEmittedAsSingleLine() {
        // String positional without enum → fallthrough
        let param = ParamDefinition(
            name: "file",
            shape: ParamShape(isRequired: true, isPositional: true),
            schema: ParamSchema(type: .string)
        )
        let book = manifest([SpellDefinition(
            identity: SpellIdentity(name: "sbx"),
            body: SpellBody(script: "echo", params: [param])
        )])
        let args = CompleteCommandArgs(wrapper: "sbx", cword: 0, tokens: ["sbx"])
        let lines = CompleteOrchestrator.compute(args: args, manifest: book)
        #expect(lines == ["__SPELLBOOK_FALLTHROUGH__"])
    }
}
