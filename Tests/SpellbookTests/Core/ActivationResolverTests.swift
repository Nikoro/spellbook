import Testing
@testable import SpellbookKit

struct ActivationResolverTests {

    // MARK: - Successful activation

    @Test func projectManifest_resolvesWithProjectSource() throws {
        let deps = makeDeps()
        deps.fileSystem.files.insert("/project/spells.yaml")
        deps.reader.manifests["/project/spells.yaml"] = simpleManifest()

        let result = try makeResolver(deps).resolve(cwd: "/project")

        #expect(result.location.source == .project)
        #expect(result.location.path == "/project/spells.yaml")
        #expect(result.manifest.spells.count == 1)
        #expect(result.manifest.spells.first?.name == "hello")
    }

    @Test func homeFallback_resolvesWithHomeFallbackSource() throws {
        let deps = makeDeps()
        deps.fileSystem.files.insert("/Users/me/spells.yaml")
        deps.reader.manifests["/Users/me/spells.yaml"] = simpleManifest()

        let result = try makeResolver(deps, home: "/Users/me")
            .resolve(cwd: "/nowhere")

        #expect(result.location.source == .homeFallback)
    }

    // MARK: - Extends chain

    @Test func extendsChain_includesParentAndChild() throws {
        let deps = makeDeps()
        deps.fileSystem.files.insert("/project/spells.yaml")
        deps.reader.manifests["/project/spells.yaml"] = SpellbookManifest(
            extends: "../shared", spells: [SpellDefinition(name: "build", script: "make")]
        )
        deps.loader.responses["../shared"] = LoadedManifest(
            manifest: SpellbookManifest(spells: [
                SpellDefinition(name: "test", script: "make test")
            ]),
            canonicalPath: "/shared/spells.yaml"
        )

        let result = try makeResolver(deps).resolve(cwd: "/project")

        #expect(result.chain == ["/shared/spells.yaml", "/project/spells.yaml"])
        #expect(result.manifest.spells.count == 2)
    }

    @Test func extendsChain_tracksSpellOriginsByManifest() throws {
        let deps = makeDeps()
        deps.fileSystem.files.insert("/project/spells.yaml")
        deps.reader.manifests["/project/spells.yaml"] = SpellbookManifest(
            extends: "../shared",
            spells: [SpellDefinition(name: "build", script: "make")]
        )
        deps.loader.responses["../shared"] = LoadedManifest(
            manifest: SpellbookManifest(spells: [
                SpellDefinition(name: "test", script: "make test")
            ]),
            canonicalPath: "/shared/spells.yaml"
        )

        let result = try makeResolver(deps).resolve(cwd: "/project")

        #expect(result.spellOrigins["build"] == "/project/spells.yaml")
        #expect(result.spellOrigins["test"] == "/shared/spells.yaml")
    }

    @Test func noExtends_chainContainsOnlyRoot() throws {
        let deps = makeDeps()
        deps.fileSystem.files.insert("/project/spells.yaml")
        deps.reader.manifests["/project/spells.yaml"] = simpleManifest()

        let result = try makeResolver(deps).resolve(cwd: "/project")

        #expect(result.chain == ["/project/spells.yaml"])
    }

    // MARK: - Validation failures

    @Test func validationFailure_throwsBeforeResult() throws {
        let deps = makeDeps()
        deps.fileSystem.files.insert("/project/spells.yaml")
        deps.reader.manifests["/project/spells.yaml"] = SpellbookManifest(spells: [
            SpellDefinition(name: "123bad", script: "echo")
        ])

        #expect(throws: SpellbookError.invalidSpellName(name: "123bad")) {
            try makeResolver(deps).resolve(cwd: "/project")
        }
    }

    // MARK: - No manifest

    @Test func noManifest_throws() {
        let deps = makeDeps()

        #expect(throws: SpellbookError.noManifestFound) {
            try makeResolver(deps).resolve(cwd: "/empty")
        }
    }

    // MARK: - Helpers

    private struct Deps {
        let fileSystem: MockFileSystem
        let reader: MockManifestReader
        let loader: MockManifestLoader
    }

    private func makeDeps() -> Deps {
        Deps(
            fileSystem: MockFileSystem(),
            reader: MockManifestReader(),
            loader: MockManifestLoader()
        )
    }

    private func makeResolver(
        _ deps: Deps,
        home: String? = nil
    ) -> ActivationResolver {
        ActivationResolver(
            fileSystem: deps.fileSystem,
            manifestReader: deps.reader,
            manifestLoader: deps.loader,
            home: home
        )
    }

    private func simpleManifest() -> SpellbookManifest {
        SpellbookManifest(spells: [
            SpellDefinition(name: "hello", script: "echo hello")
        ])
    }
}
