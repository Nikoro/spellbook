import Testing
@testable import SpellbookKit

struct CleanCommandTests {

    // MARK: - Argument parsing

    @Test func parseScope_named() throws {
        #expect(try CleanCommand.parseScope(["build"]) == .named("build"))
    }

    @Test func parseScope_orphans() throws {
        #expect(try CleanCommand.parseScope(["--orphans"]) == .orphans)
    }

    @Test func parseScope_all() throws {
        #expect(try CleanCommand.parseScope(["--all"]) == .all)
    }

    @Test func parseScope_missingArgument_throws() {
        #expect(throws: SpellbookError.cleanRequiresArgument) {
            try CleanCommand.parseScope([])
        }
    }

    @Test func parseScope_unknownFlag_throws() {
        #expect(throws: SpellbookError.cleanRequiresArgument) {
            try CleanCommand.parseScope(["--bogus"])
        }
    }

    // MARK: - Run

    @Test func clean_named_removesWrapperAndForgetsSpell() throws {
        let env = makeEnvironment()
        env.fileSystem.files.insert("/project/spells.yaml")
        env.reader.manifests["/project/spells.yaml"] = SpellbookManifest(spells: [
            SpellDefinition(name: "build", script: "make")
        ])
        env.stateStore.stored = StateSnapshot(
            updatedAt: "now",
            projects: [
                "/project": ProjectState(
                    spellsYamlHash: "h",
                    chain: ["/project/spells.yaml"],
                    spells: [
                        "build": SpellState(
                            hash: "h",
                            wrapper: "/bin/build",
                            origin: "/project/spells.yaml"
                        )
                    ]
                )
            ]
        )

        let lines = try makeCommand(env).run(arguments: ["build"], cwd: "/project")

        #expect(lines == ["Cleaned `build` (1 wrappers)."])
        #expect(env.wrapperWriter.removedPaths == ["/bin/build"])
        #expect(env.stateStore.stored?.projects["/project"]?.spells["build"] == nil)
    }

    @Test func clean_named_unknownSpell_returnsNothingToClean() throws {
        let env = makeEnvironment()
        env.fileSystem.files.insert("/project/spells.yaml")
        env.reader.manifests["/project/spells.yaml"] = SpellbookManifest(spells: [
            SpellDefinition(name: "build", script: "make")
        ])
        env.stateStore.stored = StateSnapshot(updatedAt: "now", projects: [:])

        let lines = try makeCommand(env).run(arguments: ["ghost"], cwd: "/project")

        #expect(lines == ["Nothing to clean."])
    }

    @Test func clean_all_clearsProjectAndRemovesAllWrappers() throws {
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
                        "build": SpellState(hash: "h", wrapper: "/bin/build", origin: "/project/spells.yaml"),
                        "test": SpellState(hash: "h", wrapper: "/bin/test", origin: "/project/spells.yaml")
                    ]
                )
            ]
        )

        let lines = try makeCommand(env).run(arguments: ["--all"], cwd: "/project")

        #expect(lines == ["Cleaned 2 wrappers and cleared project state."])
        #expect(env.wrapperWriter.removedPaths.sorted() == ["/bin/build", "/bin/test"])
        #expect(env.stateStore.stored?.projects["/project"] == nil)
    }

    @Test func clean_orphans_removesOnlyOrphanedSpells() throws {
        let env = makeEnvironment()
        env.fileSystem.files.insert("/project/spells.yaml")
        env.reader.manifests["/project/spells.yaml"] = SpellbookManifest(spells: [
            SpellDefinition(name: "build", script: "make")
        ])
        env.stateStore.stored = StateSnapshot(
            updatedAt: "now",
            projects: [
                "/project": ProjectState(
                    spellsYamlHash: "h",
                    chain: ["/project/spells.yaml"],
                    spells: [
                        "build": SpellState(hash: "h", wrapper: "/bin/build", origin: "/project/spells.yaml"),
                        "old": SpellState(hash: "h", wrapper: "/bin/old", origin: "/project/spells.yaml")
                    ]
                )
            ]
        )

        let lines = try makeCommand(env).run(arguments: ["--orphans"], cwd: "/project")

        #expect(lines == ["Cleaned 1 orphan wrappers: old"])
        #expect(env.wrapperWriter.removedPaths == ["/bin/old"])
        #expect(env.stateStore.stored?.projects["/project"]?.spells["build"] != nil)
        #expect(env.stateStore.stored?.projects["/project"]?.spells["old"] == nil)
    }

    @Test func clean_emptyState_returnsNothingToClean() throws {
        let env = makeEnvironment()
        env.fileSystem.files.insert("/project/spells.yaml")
        env.reader.manifests["/project/spells.yaml"] = SpellbookManifest(spells: [
            SpellDefinition(name: "build", script: "make")
        ])
        env.stateStore.stored = StateSnapshot(updatedAt: "now", projects: [:])

        let lines = try makeCommand(env).run(arguments: ["--orphans"], cwd: "/project")

        #expect(lines == ["Nothing to clean."])
    }

    // MARK: - Helpers

    private struct TestEnvironment {
        let fileSystem: MockFileSystem
        let reader: MockManifestReader
        let loader: MockManifestLoader
        let stateStore: MockStateStore
        let wrapperWriter: MockWrapperWriter
    }

    private func makeEnvironment() -> TestEnvironment {
        TestEnvironment(
            fileSystem: MockFileSystem(),
            reader: MockManifestReader(),
            loader: MockManifestLoader(),
            stateStore: MockStateStore(),
            wrapperWriter: MockWrapperWriter()
        )
    }

    private func makeCommand(_ env: TestEnvironment) -> CleanCommand {
        let resolver = ActivationResolver(
            fileSystem: env.fileSystem,
            manifestReader: env.reader,
            manifestLoader: env.loader
        )
        return CleanCommand(
            resolver: resolver,
            stateStore: env.stateStore,
            wrapperWriter: env.wrapperWriter
        )
    }
}
