import Testing
@testable import SpellbookKit

struct ListCommandTests {

    // MARK: - Compact output

    @Test func list_compactShowsSpellNames() throws {
        let env = makeEnvironment()
        env.fileSystem.files.insert("/project/spells.yaml")
        env.reader.manifests["/project/spells.yaml"] = SpellbookManifest(spells: [
            SpellDefinition(name: "hello", script: "echo hi"),
            SpellDefinition(name: "build", script: "make")
        ])

        let lines = try makeCommand(env, verbose: false).run(cwd: "/project")

        #expect(lines == ["hello", "build"])
    }

    @Test func list_compactShowsAliases() throws {
        let env = makeEnvironment()
        env.fileSystem.files.insert("/project/spells.yaml")
        env.reader.manifests["/project/spells.yaml"] = SpellbookManifest(spells: [
            SpellDefinition(
                identity: SpellIdentity(name: "test", aliases: ["t"]),
                body: SpellBody(script: "swift test")
            )
        ])

        let lines = try makeCommand(env, verbose: false).run(cwd: "/project")

        #expect(lines == ["test  (t)"])
    }

    @Test func list_overrideShowsMarker() throws {
        let env = makeEnvironment()
        env.fileSystem.files.insert("/project/spells.yaml")
        env.reader.manifests["/project/spells.yaml"] = SpellbookManifest(spells: [
            SpellDefinition(
                identity: SpellIdentity(name: "git"),
                body: SpellBody(script: "{{git}} status"),
                runtime: SpellRuntime(override: true)
            ),
            SpellDefinition(name: "build", script: "make")
        ])

        let lines = try makeCommand(env, verbose: false).run(cwd: "/project")

        #expect(lines == ["git  [override]", "build"])
    }

    // MARK: - Verbose output

    @Test func list_verboseIncludesDescription() throws {
        let env = makeEnvironment()
        env.fileSystem.files.insert("/project/spells.yaml")
        env.reader.manifests["/project/spells.yaml"] = SpellbookManifest(spells: [
            SpellDefinition(name: "build", description: "Build the project", script: "make")
        ])

        let lines = try makeCommand(env, verbose: true).run(cwd: "/project")

        #expect(lines == ["build", "  Build the project"])
    }

    @Test func list_verboseOmitsDescriptionWhenNil() throws {
        let env = makeEnvironment()
        env.fileSystem.files.insert("/project/spells.yaml")
        env.reader.manifests["/project/spells.yaml"] = SpellbookManifest(spells: [
            SpellDefinition(name: "hello", script: "echo hi")
        ])

        let lines = try makeCommand(env, verbose: true).run(cwd: "/project")

        #expect(lines == ["hello"])
    }

    // MARK: - Home fallback

    @Test func list_homeFallback_listsSpells() throws {
        let env = makeEnvironment(home: "/Users/me")
        env.fileSystem.files.insert("/Users/me/spells.yaml")
        env.reader.manifests["/Users/me/spells.yaml"] = SpellbookManifest(spells: [
            SpellDefinition(name: "global", script: "echo global")
        ])

        let lines = try makeCommand(env, verbose: false).run(cwd: "/nowhere")

        #expect(lines == ["global"])
    }

    // MARK: - Extends merge

    @Test func list_extendsChainMergesSpells() throws {
        let env = makeEnvironment()
        env.fileSystem.files.insert("/project/spells.yaml")
        env.reader.manifests["/project/spells.yaml"] = SpellbookManifest(
            extends: "/shared",
            spells: [
                SpellDefinition(name: "build", script: "make")
            ]
        )
        env.loader.responses["/shared"] = LoadedManifest(
            manifest: SpellbookManifest(spells: [
                SpellDefinition(name: "shared-cmd", script: "echo shared")
            ]),
            canonicalPath: "/shared/spells.yaml"
        )

        let lines = try makeCommand(env, verbose: false).run(cwd: "/project")

        #expect(lines.contains("build"))
        #expect(lines.contains("shared-cmd"))
    }

    // MARK: - No manifest

    @Test func list_noManifest_throwsError() {
        let env = makeEnvironment()

        #expect(throws: SpellbookError.noManifestFound) {
            try makeCommand(env, verbose: false).run(cwd: "/nowhere")
        }
    }

    // MARK: - Empty manifest

    @Test func list_emptyManifest_showsMessage() throws {
        let env = makeEnvironment()
        env.fileSystem.files.insert("/project/spells.yaml")
        env.reader.manifests["/project/spells.yaml"] = SpellbookManifest(spells: [])

        let lines = try makeCommand(env, verbose: false).run(cwd: "/project")

        #expect(lines == ["No spells defined."])
    }

    // MARK: - Helpers

    private struct TestEnvironment {
        let fileSystem: MockFileSystem
        let reader: MockManifestReader
        let loader: MockManifestLoader
        let home: String?
    }

    private func makeEnvironment(home: String? = nil) -> TestEnvironment {
        TestEnvironment(
            fileSystem: MockFileSystem(),
            reader: MockManifestReader(),
            loader: MockManifestLoader(),
            home: home
        )
    }

    private func makeCommand(_ env: TestEnvironment, verbose: Bool) -> ListCommand {
        let resolver = ActivationResolver(
            fileSystem: env.fileSystem,
            manifestReader: env.reader,
            manifestLoader: env.loader,
            home: env.home
        )
        return ListCommand(resolver: resolver, verbose: verbose)
    }
}
