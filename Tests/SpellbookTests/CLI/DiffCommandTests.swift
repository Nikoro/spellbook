import Testing
@testable import SpellbookKit

struct DiffCommandTests {

    @Test func noState_listsEverythingAsAdded() throws {
        let env = makeEnvironment()
        env.fileSystem.files.insert("/project/spells.yaml")
        env.reader.manifests["/project/spells.yaml"] = SpellbookManifest(spells: [
            SpellDefinition(name: "build", script: "make"),
            SpellDefinition(name: "test", script: "swift test")
        ])

        let lines = try makeCommand(env).run(cwd: "/project")

        #expect(lines == [
            "+ build  (/project/spells.yaml)",
            "+ test  (/project/spells.yaml)"
        ])
    }

    @Test func noChanges_returnsSentinelMessage() throws {
        let env = makeEnvironment()
        env.fileSystem.files.insert("/project/spells.yaml")
        let spell = SpellDefinition(name: "build", script: "make")
        env.reader.manifests["/project/spells.yaml"] = SpellbookManifest(spells: [spell])
        env.stateStore.stored = StateSnapshot(
            updatedAt: "now",
            projects: [
                "/project": ProjectState(
                    spellsYamlHash: "h",
                    chain: ["/project/spells.yaml"],
                    spells: [
                        "build": SpellState(
                            hash: ManifestHasher.hashSpell(spell),
                            wrapper: "/bin/build",
                            origin: "/project/spells.yaml"
                        )
                    ]
                )
            ]
        )

        let lines = try makeCommand(env).run(cwd: "/project")

        #expect(lines == ["No changes since last activation."])
    }

    @Test func changedScript_rendersTildeMarker() throws {
        let env = makeEnvironment()
        env.fileSystem.files.insert("/project/spells.yaml")
        env.reader.manifests["/project/spells.yaml"] = SpellbookManifest(spells: [
            SpellDefinition(name: "build", script: "make all")
        ])
        env.stateStore.stored = StateSnapshot(
            updatedAt: "now",
            projects: [
                "/project": ProjectState(
                    spellsYamlHash: "h",
                    chain: ["/project/spells.yaml"],
                    spells: [
                        "build": SpellState(
                            hash: "stale",
                            wrapper: "/bin/build",
                            origin: "/project/spells.yaml"
                        )
                    ]
                )
            ]
        )

        let lines = try makeCommand(env).run(cwd: "/project")

        #expect(lines == ["~ build  (/project/spells.yaml)"])
    }

    @Test func removedSpell_rendersDashMarker() throws {
        let env = makeEnvironment()
        env.fileSystem.files.insert("/project/spells.yaml")
        env.reader.manifests["/project/spells.yaml"] = SpellbookManifest(spells: [])
        env.stateStore.stored = StateSnapshot(
            updatedAt: "now",
            projects: [
                "/project": ProjectState(
                    spellsYamlHash: "h",
                    chain: ["/project/spells.yaml"],
                    spells: [
                        "old": SpellState(
                            hash: "h",
                            wrapper: "/bin/old",
                            origin: "/parent/spells.yaml"
                        )
                    ]
                )
            ]
        )

        let lines = try makeCommand(env).run(cwd: "/project")

        #expect(lines == ["- old  (/parent/spells.yaml)"])
    }

    @Test func resolverError_propagates() {
        let env = makeEnvironment()

        #expect(throws: SpellbookError.noManifestFound) {
            try makeCommand(env).run(cwd: "/nowhere")
        }
    }

    private struct TestEnvironment {
        let fileSystem: MockFileSystem
        let reader: MockManifestReader
        let loader: MockManifestLoader
        let stateStore: MockStateStore
    }

    private func makeEnvironment() -> TestEnvironment {
        TestEnvironment(
            fileSystem: MockFileSystem(),
            reader: MockManifestReader(),
            loader: MockManifestLoader(),
            stateStore: MockStateStore()
        )
    }

    private func makeCommand(_ env: TestEnvironment) -> DiffCommand {
        let resolver = ActivationResolver(
            fileSystem: env.fileSystem,
            manifestReader: env.reader,
            manifestLoader: env.loader
        )
        return DiffCommand(resolver: resolver, stateStore: env.stateStore)
    }
}
