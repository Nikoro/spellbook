import Testing
@testable import SpellbookKit

struct RunPipelineIntegrationTests {

    // MARK: - Simple script spell

    @Test func simpleSpell_executesResolvedScript() throws {
        let runner = MockProcessRunner()
        let prepared = try resolve(
            manifest: SpellbookManifest(spells: [
                SpellDefinition(name: "hello", script: "echo hello world")
            ]),
            spellName: "hello", argv: [], cwd: "/project"
        )
        try execute(prepared, with: runner)

        let inv = try #require(runner.invocations.first)
        #expect(inv.executablePath == "/usr/bin/env")
        #expect(inv.arguments == ["bash", "-c", "echo hello world"])
        #expect(inv.workingDirectory == "/project")
        #expect(inv.environment?["SPELLBOOK_SPELL_NAME"] == "hello")
    }

    // MARK: - Parameterized spell

    @Test func parameterizedSpell_substitutesValues() throws {
        let runner = MockProcessRunner()
        let prepared = try resolve(
            manifest: SpellbookManifest(spells: [
                SpellDefinition(
                    identity: SpellIdentity(name: "greet"),
                    body: SpellBody(
                        script: "echo {{name}} {{greeting}}",
                        params: [
                            ParamDefinition(name: "name"),
                            ParamDefinition(name: "greeting")
                        ]
                    )
                )
            ]),
            spellName: "greet", argv: ["Alice", "hi"], cwd: "/project"
        )
        try execute(prepared, with: runner)

        let inv = try #require(runner.invocations.first)
        #expect(inv.arguments == ["bash", "-c", "echo 'Alice' 'hi'"])
    }

    // MARK: - Switch selection

    @Test func switchBranch_resolvesCorrectScript() throws {
        let runner = MockProcessRunner()
        let prepared = try resolve(
            manifest: switchManifest(
                spell: "deploy",
                options: [("staging", "deploy -e staging"), ("prod", "deploy -e prod")]
            ),
            spellName: "deploy", argv: ["staging"], cwd: "/project"
        )
        try execute(prepared, with: runner)

        let inv = try #require(runner.invocations.first)
        #expect(inv.arguments == ["bash", "-c", "deploy -e staging"])
    }

    // MARK: - Default branch

    @Test func defaultBranch_usedWhenNoArg() throws {
        let runner = MockProcessRunner()
        let prepared = try resolve(
            manifest: switchManifest(
                spell: "build",
                options: [("debug", "make debug"), ("release", "make release")],
                defaultBranch: .key("debug")
            ),
            spellName: "build", argv: [], cwd: "/project"
        )
        try execute(prepared, with: runner)

        let inv = try #require(runner.invocations.first)
        #expect(inv.arguments == ["bash", "-c", "make debug"])
    }

    // MARK: - Exit code forwarded

    @Test func exitCode_forwardedFromExecution() throws {
        let runner = MockProcessRunner()
        runner.exitCode = 1
        let prepared = try resolve(
            manifest: SpellbookManifest(spells: [
                SpellDefinition(name: "fail", script: "exit 1")
            ]),
            spellName: "fail", argv: [], cwd: "/project"
        )
        let code = try execute(prepared, with: runner)
        #expect(code == 1)
    }

    // MARK: - Helpers

    @discardableResult
    private func execute(
        _ prepared: PreparedSpell,
        with runner: MockProcessRunner
    ) throws -> Int32 {
        try ScriptExecutor(processRunner: runner).execute(
            script: prepared.resolvedScript,
            shell: prepared.shell,
            environment: prepared.environment,
            workingDirectory: prepared.resolvedWorkingDir
        )
    }

    private func resolve(
        manifest: SpellbookManifest,
        spellName: String,
        argv: [String],
        cwd: String
    ) throws -> PreparedSpell {
        let fileSystem = MockFileSystem()
        fileSystem.files.insert("/project/spells.yaml")
        let reader = MockManifestReader()
        reader.manifests["/project/spells.yaml"] = manifest
        return try RunResolver(
            fileSystem: fileSystem,
            manifestReader: reader,
            manifestLoader: MockManifestLoader()
        ).resolve(spellName: spellName, argv: argv, cwd: cwd)
    }

    private func switchManifest(
        spell name: String,
        options: [(String, String)],
        defaultBranch: DefaultBranch = .none
    ) -> SpellbookManifest {
        let switchOptions = options.map { optName, script in
            SwitchOptionDefinition(
                name: optName,
                command: SpellDefinition(name: optName, script: script)
            )
        }
        return SpellbookManifest(spells: [
            SpellDefinition(
                identity: SpellIdentity(name: name),
                body: SpellBody(
                    switchBranches: SwitchDefinition(
                        options: switchOptions, defaultBranch: defaultBranch
                    )
                )
            )
        ])
    }
}
