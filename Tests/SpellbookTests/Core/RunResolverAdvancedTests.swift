import Testing
@testable import SpellbookKit

struct RunResolverAdvancedTests {

    // MARK: - Switch selection

    @Test func switchSelection() throws {
        let resolver = makeResolver(
            manifest: SpellbookManifest(spells: [
                SpellDefinition(
                    identity: SpellIdentity(name: "deploy"),
                    body: SpellBody(
                        switchBranches: SwitchDefinition(options: [
                            SwitchOptionDefinition(
                                name: "dev",
                                command: SpellDefinition(
                                    name: "dev", script: "deploy --env dev"
                                )
                            ),
                            SwitchOptionDefinition(
                                name: "prod",
                                command: SpellDefinition(
                                    name: "prod", script: "deploy --env prod"
                                )
                            )
                        ])
                    )
                )
            ]),
            manifestAt: "/project/spells.yaml"
        )
        let result = try resolver.resolve(
            spellName: "deploy", argv: ["prod"], cwd: "/project"
        )
        #expect(result.resolvedScript == "deploy --env prod")
    }

    // MARK: - Extends resolution

    @Test func extendsResolution() throws {
        let parent = SpellbookManifest(spells: [
            SpellDefinition(name: "shared", script: "echo shared")
        ])
        let child = SpellbookManifest(extends: "../base", spells: [
            SpellDefinition(name: "local", script: "echo local")
        ])
        let fileSystem = MockFileSystem()
        fileSystem.files.insert("/project/spells.yaml")
        let reader = MockManifestReader()
        reader.manifests["/project/spells.yaml"] = child
        let loader = MockManifestLoader()
        loader.responses["../base"] = LoadedManifest(
            manifest: parent, canonicalPath: "/base/spells.yaml"
        )
        let resolver = RunResolver(
            fileSystem: fileSystem, manifestReader: reader,
            manifestLoader: loader
        )
        let result = try resolver.resolve(
            spellName: "shared", argv: [], cwd: "/project"
        )
        #expect(result.resolvedScript == "echo shared")
    }

    // MARK: - Override placeholder

    @Test func overridePlaceholder_resolvesExternalCommand() throws {
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(
                identity: SpellIdentity(name: "git"),
                body: SpellBody(script: "{{git}} status ...args"),
                runtime: SpellRuntime(override: true)
            )
        ])
        let fileSystem = MockFileSystem()
        fileSystem.files.insert("/project/spells.yaml")
        let reader = MockManifestReader()
        reader.manifests["/project/spells.yaml"] = manifest
        let resolver = RunResolver(
            fileSystem: fileSystem, manifestReader: reader,
            manifestLoader: MockManifestLoader(),
            pathChecker: MockPathBinaryChecker(binaries: ["git"]),
            overrideLookup: FakeLookup(results: ["git": "/usr/bin/git"])
        )
        let result = try resolver.resolve(
            spellName: "git", argv: ["--all"], cwd: "/project"
        )
        #expect(result.resolvedScript == "'/usr/bin/git' status '--all'")
    }

    // MARK: - Runtime fields propagate

    @Test func runtimeFields_propagate() throws {
        let resolver = makeResolver(
            manifest: SpellbookManifest(spells: [
                SpellDefinition(
                    identity: SpellIdentity(name: "build"),
                    body: SpellBody(script: "make"),
                    runtime: SpellRuntime(
                        silent: true, workingDir: "./src", shell: "zsh"
                    )
                )
            ]),
            manifestAt: "/project/spells.yaml"
        )
        let result = try resolver.resolve(
            spellName: "build", argv: [], cwd: "/project"
        )
        #expect(result.silent)
        #expect(result.resolvedWorkingDir == "/project/./src")
        #expect(result.shell == "zsh")
    }

    // MARK: - Environment and working directory

    @Test func environmentMetadata_populated() throws {
        let resolver = makeResolver(
            manifest: SpellbookManifest(spells: [
                SpellDefinition(name: "hello", script: "echo hi")
            ]),
            manifestAt: "/project/spells.yaml"
        )
        let result = try resolver.resolve(
            spellName: "hello", argv: [], cwd: "/project/sub"
        )
        #expect(result.environment["SPELLBOOK_SPELL_NAME"] == "hello")
        #expect(result.environment["SPELLBOOK_PROJECT_ROOT"] == "/project")
        #expect(result.environment["SPELLBOOK_MANIFEST_PATH"] == "/project/spells.yaml")
        #expect(result.environment["SPELLBOOK_ORIGIN_PATH"] == "/project/spells.yaml")
        #expect(result.environment["SPELLBOOK_WORKING_DIR"] == "/project/sub")
        #expect(result.resolvedWorkingDir == "/project/sub")
    }

    @Test func tildeWorkingDir_expandsToHome() throws {
        let fileSystem = MockFileSystem()
        fileSystem.files.insert("/project/spells.yaml")
        let reader = MockManifestReader()
        reader.manifests["/project/spells.yaml"] = SpellbookManifest(spells: [
            SpellDefinition(
                identity: SpellIdentity(name: "build"),
                body: SpellBody(script: "make"),
                runtime: SpellRuntime(workingDir: "~/code")
            )
        ])
        let resolver = RunResolver(
            fileSystem: fileSystem, manifestReader: reader,
            manifestLoader: MockManifestLoader(), home: "/Users/me"
        )
        let result = try resolver.resolve(
            spellName: "build", argv: [], cwd: "/project"
        )
        #expect(result.resolvedWorkingDir == "/Users/me/code")
    }

    // MARK: - Helpers

    private struct FakeLookup: OverrideLookup {
        let results: [String: String]
        func externalCommand(for spellName: String) -> String? {
            results[spellName]
        }
    }

    private func makeResolver(
        manifest: SpellbookManifest,
        manifestAt path: String
    ) -> RunResolver {
        let fileSystem = MockFileSystem()
        fileSystem.files.insert(path)
        let reader = MockManifestReader()
        reader.manifests[path] = manifest
        return RunResolver(
            fileSystem: fileSystem, manifestReader: reader,
            manifestLoader: MockManifestLoader()
        )
    }
}
