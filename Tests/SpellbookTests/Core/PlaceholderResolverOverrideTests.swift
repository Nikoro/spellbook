import Testing
@testable import SpellbookKit

struct PlaceholderResolverOverrideTests {
    private struct FakeOverrideLookup: OverrideLookup {
        let results: [String: String]
        func externalCommand(for spellName: String) -> String? { results[spellName] }
    }

    private let resolver = PlaceholderResolver()

    @Test func overrideSpell_resolvesSpellNamePlaceholder_throughLookup() {
        let spell = SpellDefinition(
            identity: SpellIdentity(name: "git"),
            runtime: SpellRuntime(override: true)
        )
        let lookup = FakeOverrideLookup(results: ["git": "/usr/bin/git"])

        let result = resolver.resolve(
            script: "{{git}} commit -m 'test'",
            spell: spell,
            arguments: ParsedArguments(),
            overrideLookup: lookup
        )

        #expect(result == "'/usr/bin/git' commit -m 'test'")
    }

    @Test func overrideSpell_hyphenatedName_resolvesThroughLookup() {
        let spell = SpellDefinition(
            identity: SpellIdentity(name: "my-tool"),
            runtime: SpellRuntime(override: true)
        )
        let lookup = FakeOverrideLookup(results: ["my-tool": "/usr/local/bin/my-tool"])

        let result = resolver.resolve(
            script: "{{my-tool}} --verbose",
            spell: spell,
            arguments: ParsedArguments(),
            overrideLookup: lookup
        )

        #expect(result == "'/usr/local/bin/my-tool' --verbose")
    }

    @Test func overrideSpell_missingExternalCommand_leavesPlaceholderUnchanged() {
        let spell = SpellDefinition(
            identity: SpellIdentity(name: "git"),
            runtime: SpellRuntime(override: true)
        )
        let lookup = FakeOverrideLookup(results: [:])

        let result = resolver.resolve(
            script: "{{git}} status",
            spell: spell,
            arguments: ParsedArguments(),
            overrideLookup: lookup
        )

        #expect(result == "{{git}} status")
    }

    @Test func nonOverrideSpell_doesNotResolveSpellNamePlaceholder() {
        let spell = SpellDefinition(
            identity: SpellIdentity(name: "git")
        )
        let lookup = FakeOverrideLookup(results: ["git": "/usr/bin/git"])

        let result = resolver.resolve(
            script: "{{git}} status",
            spell: spell,
            arguments: ParsedArguments(),
            overrideLookup: lookup
        )

        #expect(result == "{{git}} status")
    }

    @Test func overrideSpell_paramPlaceholders_stillResolveNormally() {
        let spell = SpellDefinition(
            identity: SpellIdentity(name: "git"),
            body: SpellBody(
                script: nil,
                params: [ParamDefinition(name: "message")]
            ),
            runtime: SpellRuntime(override: true)
        )
        let lookup = FakeOverrideLookup(results: ["git": "/usr/bin/git"])
        let arguments = ParsedArguments(values: ["message": "hello world"])

        let result = resolver.resolve(
            script: "{{git}} commit -m {{message}}",
            spell: spell,
            arguments: arguments,
            overrideLookup: lookup
        )

        #expect(result == "'/usr/bin/git' commit -m 'hello world'")
    }

    @Test func overrideSpell_shellEscapesExternalCommandPath() {
        let spell = SpellDefinition(
            identity: SpellIdentity(name: "git"),
            runtime: SpellRuntime(override: true)
        )
        let lookup = FakeOverrideLookup(results: ["git": "/path with spaces/it's git"])

        let result = resolver.resolve(
            script: "{{git}} status",
            spell: spell,
            arguments: ParsedArguments(),
            overrideLookup: lookup
        )

        #expect(result == "'/path with spaces/it'\\''s git' status")
    }
}
