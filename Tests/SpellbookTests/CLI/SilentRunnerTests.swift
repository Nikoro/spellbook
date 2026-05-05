import Testing
@testable import SpellbookKit

struct SilentRunnerTests {

    // MARK: - US-007A: Success path

    @Test func silentSuccess_discardsOutput() throws {
        let sut = makeSUT(tty: true)

        let code = try sut.runner.execute(
            spell: makeSpell(silent: true)
        )

        #expect(code == 0)
        assertContains(sut.terminal.writtenLines, "✓ test")
    }

    @Test func silentSuccess_clearsThenRestores() throws {
        let sut = makeSUT(tty: true)

        try sut.runner.execute(spell: makeSpell(silent: true))

        #expect(sut.terminal.cursorHidden == false)
        #expect(sut.terminal.linesCleared >= 1)
    }

    // MARK: - US-007A: Spinner label

    @Test func customLabel_usedInOutput() throws {
        let sut = makeSUT(tty: true)

        try sut.runner.execute(
            spell: makeSpell(silent: true),
            label: "deploy:staging"
        )

        assertContains(
            sut.terminal.writtenLines, "✓ deploy:staging"
        )
    }

    @Test func defaultLabel_usesSpellName() throws {
        let sut = makeSUT(tty: true)

        try sut.runner.execute(
            spell: makeSpell(name: "build", silent: true)
        )

        assertContains(sut.terminal.writtenLines, "✓ build")
    }

    // MARK: - US-007D: Non-TTY passthrough

    @Test func nonTTY_streamsNormally() throws {
        let sut = makeSUT(tty: false)

        try sut.runner.execute(spell: makeSpell(silent: true))

        #expect(sut.processRunner.invocations.count == 1)
        #expect(sut.terminal.written.isEmpty)
        #expect(sut.terminal.writtenLines.isEmpty)
    }

    @Test func nonSilent_passesThrough() throws {
        let sut = makeSUT(tty: true)

        try sut.runner.execute(spell: makeSpell(silent: false))

        #expect(sut.processRunner.invocations.count == 1)
        #expect(sut.terminal.writtenLines.isEmpty)
    }

    // MARK: - US-007D: Label uses invocation path

    @Test func spinnerLabel_usesSpellName() throws {
        let sut = makeSUT(tty: true)

        try sut.runner.execute(
            spell: makeSpell(name: "deploy", silent: true)
        )

        let spinner = sut.terminal.written.first ?? ""
        #expect(spinner.contains("deploy"))
    }

    // MARK: - Launch failure

    @Test func launchFailure_restoresCursor() {
        let cap = MockCapturingRunner()
        cap.errorToThrow = SpellbookError.scriptLaunchFailed(
            shell: "bash", reason: "not found"
        )
        let sut = makeSUT(
            tty: true, capturing: cap
        )

        #expect(throws: SpellbookError.scriptLaunchFailed(shell: "bash", reason: "not found")) {
            try sut.runner.execute(
                spell: makeSpell(silent: true)
            )
        }

        #expect(sut.terminal.cursorHidden == false)
    }
}

// MARK: - Helpers

extension SilentRunnerTests {
    struct SUT {
        let runner: SilentRunner
        let terminal: MockTerminal
        let processRunner: MockProcessRunner
    }

    func makeSUT(
        tty: Bool,
        capturing: MockCapturingRunner? = nil
    ) -> SUT {
        let terminal = MockTerminal(
            capabilities: TerminalCapabilities(
                isTTY: tty,
                supportsColor: false,
                supportsRawMode: false
            )
        )
        let processRunner = MockProcessRunner()
        let cap = capturing ?? MockCapturingRunner()
        let runner = SilentRunner(
            terminal: terminal,
            capturingRunner: cap,
            scriptExecutor: ScriptExecutor(
                processRunner: processRunner
            )
        )
        return SUT(runner: runner, terminal: terminal, processRunner: processRunner)
    }

    func makeSpell(
        name: String = "test",
        silent: Bool = false
    ) -> PreparedSpell {
        PreparedSpell(
            name: name,
            resolvedScript: "echo hello",
            resolvedWorkingDir: "/tmp",
            silent: silent,
            manifestPath: "/tmp/spells.yaml"
        )
    }

    func assertContains(
        _ lines: [String],
        _ substring: String,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        let found = lines.contains {
            $0.contains(substring)
        }
        #expect(found, "Expected \(substring) in \(lines)", sourceLocation: sourceLocation)
    }
}
