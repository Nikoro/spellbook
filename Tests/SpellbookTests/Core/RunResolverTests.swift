import Testing
@testable import SpellbookKit

struct RunResolverTests {

    @Test func simpleSpell_resolvesScript() throws {
        let resolver = makeResolver(
            manifest: SpellbookManifest(spells: [
                SpellDefinition(name: "hello", script: "echo hi")
            ]),
            manifestAt: "/project/spells.yaml"
        )

        let result = try resolver.resolve(
            spellName: "hello", argv: [], cwd: "/project"
        )

        #expect(result.name == "hello")
        #expect(result.resolvedScript == "echo hi")
        #expect(result.manifestPath == "/project/spells.yaml")
    }

    @Test func spellNotFound_throws() {
        let resolver = makeResolver(
            manifest: SpellbookManifest(spells: [
                SpellDefinition(name: "hello", script: "echo hi")
            ]),
            manifestAt: "/project/spells.yaml"
        )

        #expect(throws: SpellbookError.spellNotFound(name: "goodbye")) {
            try resolver.resolve(spellName: "goodbye", argv: [], cwd: "/project")
        }
    }

    @Test func noManifest_throws() {
        let resolver = RunResolver(
            fileSystem: MockFileSystem(),
            manifestReader: MockManifestReader(),
            manifestLoader: MockManifestLoader()
        )

        #expect(throws: SpellbookError.noManifestFound) {
            try resolver.resolve(spellName: "hello", argv: [], cwd: "/empty")
        }
    }

    @Test func resolveByAlias() throws {
        let resolver = makeResolver(
            manifest: SpellbookManifest(spells: [
                SpellDefinition(
                    identity: SpellIdentity(name: "build", aliases: ["b"]),
                    body: SpellBody(script: "swift build")
                )
            ]),
            manifestAt: "/project/spells.yaml"
        )

        let result = try resolver.resolve(
            spellName: "b", argv: [], cwd: "/project"
        )

        #expect(result.name == "build")
        #expect(result.resolvedScript == "swift build")
    }

    @Test func paramSubstitution() throws {
        let resolver = makeResolver(
            manifest: SpellbookManifest(spells: [
                SpellDefinition(
                    identity: SpellIdentity(name: "greet"),
                    body: SpellBody(
                        script: "echo {{name}}",
                        params: [ParamDefinition(name: "name")]
                    )
                )
            ]),
            manifestAt: "/project/spells.yaml"
        )

        let result = try resolver.resolve(
            spellName: "greet", argv: ["world"], cwd: "/project"
        )

        #expect(result.resolvedScript == "echo 'world'")
    }

    @Test func passthroughExpansion() throws {
        let resolver = makeResolver(
            manifest: SpellbookManifest(spells: [
                SpellDefinition(name: "run", script: "cmd ...args")
            ]),
            manifestAt: "/project/spells.yaml"
        )

        let result = try resolver.resolve(
            spellName: "run", argv: ["-v", "--force"], cwd: "/project"
        )

        #expect(result.resolvedScript == "cmd '-v' '--force'")
    }

    @Test func validationError_throws() {
        let resolver = makeResolver(
            manifest: SpellbookManifest(spells: [
                SpellDefinition(name: "1invalid", script: "echo bad")
            ]),
            manifestAt: "/project/spells.yaml"
        )

        #expect(throws: SpellbookError.invalidSpellName(name: "1invalid")) {
            try resolver.resolve(spellName: "1invalid", argv: [], cwd: "/project")
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
            fileSystem: fileSystem,
            manifestReader: reader,
            manifestLoader: MockManifestLoader()
        )
    }
}
