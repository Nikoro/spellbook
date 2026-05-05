import Testing
@testable import SpellbookKit

struct RunCommandTests {

    // MARK: - Argument parsing

    @Test func parse_extractsSpellNameCwdAndArgv() throws {
        let parsed = try RunCommand.parseArguments(["hello", "--cwd", "/project", "--", "arg1", "arg2"])
        #expect(parsed.spellName == "hello")
        #expect(parsed.cwd == "/project")
        #expect(parsed.spellArgv == ["arg1", "arg2"])
    }

    @Test func parse_cwdBeforeSpellName_isTreatedAsSpellName() throws {
        let parsed = try RunCommand.parseArguments(["hello", "--cwd", "/project"])
        #expect(parsed.spellName == "hello")
        #expect(parsed.cwd == "/project")
        #expect(parsed.spellArgv == [])
    }

    @Test func parse_noArgv_returnsEmptySpellArgv() throws {
        let parsed = try RunCommand.parseArguments(["build", "--cwd", "/app", "--"])
        #expect(parsed.spellName == "build")
        #expect(parsed.spellArgv == [])
    }

    @Test func parse_missingSpellName_throws() {
        #expect(throws: SpellbookError.runMissingSpellName) {
            try RunCommand.parseArguments([])
        }
    }

    @Test func parse_missingCwd_throws() {
        #expect(throws: SpellbookError.runMissingCwd) {
            try RunCommand.parseArguments(["hello", "--", "arg"])
        }
    }

    @Test func parse_cwdWithoutValue_throws() {
        #expect(throws: SpellbookError.runMissingCwd) {
            try RunCommand.parseArguments(["hello", "--cwd"])
        }
    }

    // MARK: - Dispatch

    @Test func run_dispatchesToResolverAndExecutor() throws {
        let env = makeEnvironment(spell: "hello", script: "echo hi", cwd: "/project")
        let command = makeCommand(env)

        let code = try command.run(arguments: ["hello", "--cwd", "/project", "--"])

        #expect(code == 0)
        #expect(env.runner.invocations.count == 1)
        let inv = env.runner.invocations[0]
        #expect(inv.arguments == ["bash", "-c", "echo hi"])
        #expect(inv.workingDirectory == "/project")
    }

    @Test func run_forwardsExitCode() throws {
        let env = makeEnvironment(spell: "fail", script: "exit 1", cwd: "/project")
        env.runner.exitCode = 42
        let command = makeCommand(env)

        let code = try command.run(arguments: ["fail", "--cwd", "/project", "--"])

        #expect(code == 42)
    }

    @Test func run_passesSpellArgvToResolver() throws {
        let env = makeEnvironment(
            spell: "greet",
            script: "echo {{name}}",
            cwd: "/project",
            params: [ParamDefinition(name: "name")]
        )
        let command = makeCommand(env)

        let code = try command.run(arguments: ["greet", "--cwd", "/project", "--", "Alice"])

        #expect(code == 0)
        let inv = try #require(env.runner.invocations.first)
        #expect(inv.arguments[2].contains("Alice"))
    }

    // MARK: - Helpers

    private struct TestEnvironment {
        let fileSystem: MockFileSystem
        let reader: MockManifestReader
        let loader: MockManifestLoader
        let runner: MockProcessRunner
        let state: MockStateStore
    }

    private func makeEnvironment(
        spell name: String = "hello",
        script: String = "echo hi",
        cwd: String = "/project",
        params: [ParamDefinition] = []
    ) -> TestEnvironment {
        let fileSystem = MockFileSystem()
        fileSystem.files.insert(cwd + "/spells.yaml")
        let reader = MockManifestReader()
        reader.manifests[cwd + "/spells.yaml"] = SpellbookManifest(spells: [
            SpellDefinition(
                identity: SpellIdentity(name: name),
                body: SpellBody(script: script, params: params)
            )
        ])
        return TestEnvironment(
            fileSystem: fileSystem,
            reader: reader,
            loader: MockManifestLoader(),
            runner: MockProcessRunner(),
            state: MockStateStore()
        )
    }

    private func nonTTYCapabilities() -> TerminalCapabilities {
        TerminalCapabilities(isTTY: false, supportsColor: false, supportsRawMode: false)
    }

    private func makeCommand(_ env: TestEnvironment) -> RunCommand {
        RunCommand(
            resolver: RunResolver(
                fileSystem: env.fileSystem,
                manifestReader: env.reader,
                manifestLoader: env.loader
            ),
            silentRunner: SilentRunner(
                terminal: MockTerminal(capabilities: nonTTYCapabilities()),
                capturingRunner: MockCapturingRunner(),
                scriptExecutor: ScriptExecutor(processRunner: env.runner)
            ),
            stateStore: env.state
        )
    }
}
