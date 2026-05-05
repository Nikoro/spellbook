import Testing
@testable import SpellbookKit

struct OverrideMultiLevelTests {

    // MARK: - Multi-level overrides resolve external binaries

    @Test func overridePlaceholder_resolvesToExternalBinary() throws {
        let resolved = try resolveThreeLevelChain(
            grandparentSpell: SpellDefinition(
                identity: SpellIdentity(name: "git"),
                body: SpellBody(script: "{{git}} ...args"),
                runtime: SpellRuntime(override: true)
            )
        )

        let git = try #require(
            resolved.spells.first { $0.name == "git" }
        )
        #expect(git.override)

        let lookup = FakeLookup(results: ["git": "/usr/bin/git"])
        let result = PlaceholderResolver().resolve(
            script: git.script ?? "",
            spell: git,
            arguments: ParsedArguments(passthrough: ["status"]),
            overrideLookup: lookup
        )
        #expect(result == "'/usr/bin/git' 'status'")
    }

    @Test func overridePlaceholder_neverResolvesToSpell() throws {
        let resolved = try resolveThreeLevelChain(
            grandparentSpell: SpellDefinition(
                identity: SpellIdentity(name: "git"),
                body: SpellBody(script: "{{git}} ...args"),
                runtime: SpellRuntime(override: true)
            )
        )

        let git = try #require(
            resolved.spells.first { $0.name == "git" }
        )
        let lookup = FakeLookup(results: [:])
        let result = PlaceholderResolver().resolve(
            script: git.script ?? "",
            spell: git,
            arguments: ParsedArguments(passthrough: ["status"]),
            overrideLookup: lookup
        )
        #expect(result == "{{git}} 'status'")
    }

    @Test func childOverridesBuiltinParent_stillRejected() throws {
        let parent = SpellbookManifest(spells: [
            SpellDefinition(name: "eval", script: "echo parent")
        ])
        let child = SpellbookManifest(extends: "../base", spells: [
            SpellDefinition(
                identity: SpellIdentity(name: "eval"),
                body: SpellBody(script: "echo child"),
                runtime: SpellRuntime(override: true)
            )
        ])
        let loader = MockManifestLoader()
        loader.responses["../base"] = LoadedManifest(
            manifest: parent, canonicalPath: "/base/spells.yaml"
        )

        let resolved = try ExtendsResolver(loader: loader)
            .resolve(child, basePath: "/project/spells.yaml")

        let checker = MockPathBinaryChecker(binaries: [])
        let errors = SpellbookValidator(pathChecker: checker)
            .validate(resolved)
        #expect(errors == [.spellIsShellStateBuiltin(spell: "eval")])
    }

    // MARK: - Helpers

    private struct FakeLookup: OverrideLookup {
        let results: [String: String]
        func externalCommand(for spellName: String) -> String? {
            results[spellName]
        }
    }

    private func resolveThreeLevelChain(
        grandparentSpell: SpellDefinition
    ) throws -> SpellbookManifest {
        let grandparent = SpellbookManifest(spells: [grandparentSpell])
        let parent = SpellbookManifest(extends: "../gp", spells: [
            SpellDefinition(name: "deploy", script: "./deploy")
        ])
        let child = SpellbookManifest(extends: "../parent", spells: [
            SpellDefinition(name: "test", script: "./test")
        ])
        let loader = MockManifestLoader()
        loader.responses["../parent"] = LoadedManifest(
            manifest: parent,
            canonicalPath: "/parent/spells.yaml"
        )
        loader.responses["../gp"] = LoadedManifest(
            manifest: grandparent, canonicalPath: "/gp/spells.yaml"
        )
        return try ExtendsResolver(loader: loader)
            .resolve(child, basePath: "/child/spells.yaml")
    }
}
