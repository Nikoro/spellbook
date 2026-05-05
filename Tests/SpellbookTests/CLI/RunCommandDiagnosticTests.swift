import Testing
@testable import SpellbookKit

struct RunCommandDiagnosticTests {

    @Test func missingSpell_withStateMatch_throwsSuggestions() {
        let env = makeEmptyEnvironment(cwd: "/other")
        env.state.stored = StateSnapshot(
            updatedAt: "2026-01-01T00:00:00Z",
            projects: [
                "/project": ProjectState(
                    spellsYamlHash: "sha256:abc",
                    chain: ["/project/spells.yaml"],
                    spells: ["hello": SpellState(
                        hash: "sha256:def",
                        wrapper: "/bin/hello",
                        origin: "/project/spells.yaml"
                    )]
                )
            ]
        )
        let command = makeCommand(env)

        #expect(throws: SpellbookError.spellNotFoundWithSuggestions(name: "hello", projects: ["/project"])) {
            try command.run(arguments: ["hello", "--cwd", "/other", "--"])
        }
    }

    @Test func missingSpell_withNoState_throwsPlainNotFound() {
        let env = makeEmptyEnvironment(cwd: "/other")
        let command = makeCommand(env)

        #expect(throws: SpellbookError.spellNotFound(name: "hello")) {
            try command.run(arguments: ["hello", "--cwd", "/other", "--"])
        }
    }

    @Test func missingSpell_stateExistsButNoMatch_throwsPlainNotFound() {
        let env = makeEmptyEnvironment(cwd: "/other")
        env.state.stored = StateSnapshot(
            updatedAt: "2026-01-01T00:00:00Z",
            projects: [
                "/project": ProjectState(
                    spellsYamlHash: "sha256:abc",
                    chain: ["/project/spells.yaml"],
                    spells: ["build": SpellState(
                        hash: "sha256:def",
                        wrapper: "/bin/build",
                        origin: "/project/spells.yaml"
                    )]
                )
            ]
        )
        let command = makeCommand(env)

        #expect(throws: SpellbookError.spellNotFound(name: "hello")) {
            try command.run(arguments: ["hello", "--cwd", "/other", "--"])
        }
    }

    // MARK: - Helpers

    private struct TestEnvironment {
        let fileSystem: MockFileSystem
        let reader: MockManifestReader
        let loader: MockManifestLoader
        let runner: MockProcessRunner
        let state: MockStateStore
    }

    private func makeEmptyEnvironment(cwd: String) -> TestEnvironment {
        let fileSystem = MockFileSystem()
        fileSystem.files.insert(cwd + "/spells.yaml")
        let reader = MockManifestReader()
        reader.manifests[cwd + "/spells.yaml"] = SpellbookManifest(spells: [])
        return TestEnvironment(
            fileSystem: fileSystem,
            reader: reader,
            loader: MockManifestLoader(),
            runner: MockProcessRunner(),
            state: MockStateStore()
        )
    }

    private func makeCommand(_ env: TestEnvironment) -> RunCommand {
        RunCommand(
            resolver: RunResolver(
                fileSystem: env.fileSystem,
                manifestReader: env.reader,
                manifestLoader: env.loader
            ),
            silentRunner: SilentRunner(
                terminal: MockTerminal(
                    capabilities: TerminalCapabilities(
                        isTTY: false, supportsColor: false, supportsRawMode: false
                    )
                ),
                capturingRunner: MockCapturingRunner(),
                scriptExecutor: ScriptExecutor(processRunner: env.runner)
            ),
            stateStore: env.state
        )
    }
}
