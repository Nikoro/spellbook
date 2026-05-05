import Testing
@testable import SpellbookKit

struct ActivationIntegrationTests {

    // MARK: - Successful activation

    @Test func activation_writesWrappersAndState() throws {
        let env = makeEnvironment()
        env.fileSystem.files.insert("/project/spells.yaml")
        env.reader.manifests["/project/spells.yaml"] = SpellbookManifest(spells: [
            SpellDefinition(name: "hello", script: "echo hi")
        ])
        env.content.contents["/project/spells.yaml"] = "hello: echo hi"

        let summary = try makeCommand(env).activate(cwd: "/project")

        #expect(summary.source == .project)
        #expect(summary.spellCount == 1)
        #expect(summary.wrapperCount == 1)
        #expect(env.writer.writtenFiles.count == 1)
        #expect(env.state.stored != nil)
    }

    @Test func activation_aliasesProduceExtraWrappers() throws {
        let env = makeEnvironment()
        env.fileSystem.files.insert("/project/spells.yaml")
        env.reader.manifests["/project/spells.yaml"] = SpellbookManifest(spells: [
            SpellDefinition(
                identity: SpellIdentity(name: "test", aliases: ["t"]),
                body: SpellBody(script: "swift test")
            )
        ])

        let summary = try makeCommand(env).activate(cwd: "/project")

        #expect(summary.spellCount == 1)
        #expect(summary.wrapperCount == 2)
    }

    // MARK: - Home fallback source

    @Test func activation_homeFallback_identifiesSource() throws {
        let env = makeEnvironment(home: "/Users/me")
        env.fileSystem.files.insert("/Users/me/spells.yaml")
        env.reader.manifests["/Users/me/spells.yaml"] = SpellbookManifest(spells: [
            SpellDefinition(name: "global", script: "echo global")
        ])

        let summary = try makeCommand(env).activate(cwd: "/nowhere")

        #expect(summary.source == .homeFallback)
        #expect(summary.manifestPath == "/Users/me/spells.yaml")
    }

    // MARK: - State records project

    @Test func activation_stateRecordsProject() throws {
        let env = makeEnvironment()
        env.fileSystem.files.insert("/project/spells.yaml")
        env.reader.manifests["/project/spells.yaml"] = SpellbookManifest(spells: [
            SpellDefinition(name: "build", script: "make")
        ])

        _ = try makeCommand(env).activate(cwd: "/project")

        let stored = try #require(env.state.stored)
        let project = try #require(stored.projects["/project"])
        #expect(project.chain == ["/project/spells.yaml"])
        #expect(project.spells["build"] != nil)
    }

    @Test func activation_statePreservesOriginForInheritedSpells() throws {
        let env = makeEnvironment()
        env.fileSystem.files.insert("/project/spells.yaml")
        env.reader.manifests["/project/spells.yaml"] = SpellbookManifest(
            extends: "../shared",
            spells: [SpellDefinition(name: "build", script: "make")]
        )
        env.loader.responses["../shared"] = LoadedManifest(
            manifest: SpellbookManifest(spells: [
                SpellDefinition(name: "test", script: "make test")
            ]),
            canonicalPath: "/shared/spells.yaml"
        )
        env.content.contents["/project/spells.yaml"] = """
        extends: ../shared
        spells:
          build:
            script: make
        """

        _ = try makeCommand(env).activate(cwd: "/project")

        let stored = try #require(env.state.stored)
        let project = try #require(stored.projects["/project"])
        #expect(project.spells["build"]?.origin == "/project/spells.yaml")
        #expect(project.spells["test"]?.origin == "/shared/spells.yaml")
    }

    // MARK: - Validation failure prevents writes

    @Test func validationFailure_noWrappersOrState() {
        let env = makeEnvironment()
        env.fileSystem.files.insert("/project/spells.yaml")
        env.reader.manifests["/project/spells.yaml"] = SpellbookManifest(spells: [
            SpellDefinition(name: "123bad", script: "echo")
        ])

        #expect(throws: SpellbookError.invalidSpellName(name: "123bad")) {
            try makeCommand(env).activate(cwd: "/project")
        }
        #expect(env.writer.writtenFiles.isEmpty)
        #expect(env.state.stored == nil)
    }

    // MARK: - Wrapper failure prevents state

    @Test func wrapperWriteFailure_noStateWritten() {
        let env = makeEnvironment()
        env.fileSystem.files.insert("/project/spells.yaml")
        env.reader.manifests["/project/spells.yaml"] = SpellbookManifest(spells: [
            SpellDefinition(name: "hello", script: "echo hi")
        ])
        env.writer.failAfterCount = 0

        #expect(throws: WrapperWriteError.simulatedFailure) {
            try makeCommand(env).activate(cwd: "/project")
        }
        #expect(env.state.stored == nil)
    }

    // MARK: - Helpers

    private struct TestEnvironment {
        let fileSystem: MockFileSystem
        let reader: MockManifestReader
        let loader: MockManifestLoader
        let writer: MockWrapperWriter
        let state: MockStateStore
        let content: MockManifestContentReader
        let home: String?
    }

    private func makeEnvironment(home: String? = nil) -> TestEnvironment {
        TestEnvironment(
            fileSystem: MockFileSystem(),
            reader: MockManifestReader(),
            loader: MockManifestLoader(),
            writer: MockWrapperWriter(),
            state: MockStateStore(),
            content: MockManifestContentReader(),
            home: home
        )
    }

    private func makeCommand(
        _ env: TestEnvironment,
        fileLock: FileLock? = nil
    ) -> ActivationCommand {
        let resolver = ActivationResolver(
            fileSystem: env.fileSystem,
            manifestReader: env.reader,
            manifestLoader: env.loader,
            home: env.home
        )
        let generator = WrapperGenerator(
            writer: env.writer,
            binDirectory: "/home/.spellbook/bin"
        )
        return ActivationCommand(
            resolver: resolver,
            wrapperGenerator: generator,
            stateStore: env.state,
            manifestContent: env.content,
            fileLock: fileLock
        )
    }
}
