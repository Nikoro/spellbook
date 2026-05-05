import Testing
@testable import SpellbookKit

struct OverrideExtendsTests {

    // MARK: - Extends preserves closer-manifest override semantics

    @Test func parentOverrideSpell_inheritedByChild() throws {
        let parent = SpellbookManifest(spells: [
            SpellDefinition(
                identity: SpellIdentity(name: "git"),
                body: SpellBody(script: "{{git}} ...args"),
                runtime: SpellRuntime(override: true)
            )
        ])
        let child = SpellbookManifest(extends: "../base", spells: [
            SpellDefinition(name: "deploy", script: "./deploy")
        ])
        let loader = MockManifestLoader()
        loader.responses["../base"] = LoadedManifest(
            manifest: parent, canonicalPath: "/base/spells.yaml"
        )

        let resolved = try ExtendsResolver(loader: loader)
            .resolve(child, basePath: "/project/spells.yaml")

        let git = try #require(resolved.spells.first { $0.name == "git" })
        #expect(git.override)
        #expect(git.script == "{{git}} ...args")
    }

    @Test func childOverridesParentOverride_childWins() throws {
        let parent = SpellbookManifest(spells: [
            SpellDefinition(
                identity: SpellIdentity(name: "git"),
                body: SpellBody(script: "{{git}} ...args"),
                runtime: SpellRuntime(override: true)
            )
        ])
        let child = SpellbookManifest(extends: "../base", spells: [
            SpellDefinition(name: "git", script: "echo custom git")
        ])
        let loader = MockManifestLoader()
        loader.responses["../base"] = LoadedManifest(
            manifest: parent, canonicalPath: "/base/spells.yaml"
        )

        let resolved = try ExtendsResolver(loader: loader)
            .resolve(child, basePath: "/project/spells.yaml")

        let git = try #require(
            resolved.spells.first { $0.name == "git" }
        )
        #expect(git.override == false)
        #expect(git.script == "echo custom git")
    }

    @Test func childAddsOverride_toNonOverrideParent() throws {
        let parent = SpellbookManifest(spells: [
            SpellDefinition(name: "git", script: "echo parent git")
        ])
        let child = SpellbookManifest(extends: "../base", spells: [
            SpellDefinition(
                identity: SpellIdentity(name: "git"),
                body: SpellBody(script: "{{git}} ...args"),
                runtime: SpellRuntime(override: true)
            )
        ])
        let loader = MockManifestLoader()
        loader.responses["../base"] = LoadedManifest(
            manifest: parent, canonicalPath: "/base/spells.yaml"
        )

        let resolved = try ExtendsResolver(loader: loader)
            .resolve(child, basePath: "/project/spells.yaml")

        let git = try #require(
            resolved.spells.first { $0.name == "git" }
        )
        #expect(git.override)
    }

    @Test func parentAliases_notInherited_whenChildOverrides() throws {
        let parent = SpellbookManifest(spells: [
            SpellDefinition(
                identity: SpellIdentity(name: "git", aliases: ["g", "gi"]),
                body: SpellBody(script: "{{git}} ...args"),
                runtime: SpellRuntime(override: true)
            )
        ])
        let child = SpellbookManifest(extends: "../base", spells: [
            SpellDefinition(
                identity: SpellIdentity(name: "git"),
                body: SpellBody(script: "{{git}} --verbose ...args"),
                runtime: SpellRuntime(override: true)
            )
        ])
        let loader = MockManifestLoader()
        loader.responses["../base"] = LoadedManifest(
            manifest: parent, canonicalPath: "/base/spells.yaml"
        )

        let resolved = try ExtendsResolver(loader: loader)
            .resolve(child, basePath: "/project/spells.yaml")

        let git = try #require(
            resolved.spells.first { $0.name == "git" }
        )
        #expect(git.aliases == [])
    }

    @Test func mergedManifest_inheritsPathShadowError() throws {
        let parent = SpellbookManifest(spells: [
            SpellDefinition(name: "ls", script: "ls --color")
        ])
        let child = SpellbookManifest(extends: "../base", spells: [
            SpellDefinition(name: "deploy", script: "./deploy")
        ])
        let loader = MockManifestLoader()
        loader.responses["../base"] = LoadedManifest(
            manifest: parent, canonicalPath: "/base/spells.yaml"
        )

        let resolved = try ExtendsResolver(loader: loader)
            .resolve(child, basePath: "/project/spells.yaml")

        let checker = MockPathBinaryChecker(binaries: ["ls"])
        let errors = SpellbookValidator(pathChecker: checker)
            .validate(resolved)
        #expect(errors == [.spellShadowsPathBinary(spell: "ls")])
    }

    @Test func inheritedBuiltinOverride_isRejectedAfterMerge() throws {
        let parent = SpellbookManifest(spells: [
            SpellDefinition(
                identity: SpellIdentity(name: "cd"),
                body: SpellBody(script: "cd ...args"),
                runtime: SpellRuntime(override: true)
            )
        ])
        let child = SpellbookManifest(extends: "../base", spells: [])
        let loader = MockManifestLoader()
        loader.responses["../base"] = LoadedManifest(
            manifest: parent, canonicalPath: "/base/spells.yaml"
        )

        let resolved = try ExtendsResolver(loader: loader)
            .resolve(child, basePath: "/project/spells.yaml")

        let checker = MockPathBinaryChecker(binaries: [])
        let errors = SpellbookValidator(pathChecker: checker)
            .validate(resolved)
        #expect(errors == [.spellIsShellStateBuiltin(spell: "cd")])
    }
}
