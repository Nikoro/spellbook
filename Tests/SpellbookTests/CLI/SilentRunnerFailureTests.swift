import Testing
@testable import SpellbookKit

struct SilentRunnerFailureTests {

    // MARK: - US-007B: Failure path

    @Test func silentFailure_flushesStdout() throws {
        let cap = MockCapturingRunner()
        cap.result = CapturedProcessResult(
            exitCode: 1,
            stdout: Array("out\n".utf8)
        )
        let sut = makeSUT(cap)

        let code = try sut.runner.execute(
            spell: makeSpell(silent: true)
        )

        #expect(code == 1)
        assertContains(sut.terminal.written, "out\n")
    }

    @Test func silentFailure_flushesStderr() throws {
        let cap = MockCapturingRunner()
        cap.result = CapturedProcessResult(
            exitCode: 2,
            stderr: Array("err\n".utf8)
        )
        let sut = makeSUT(cap)

        try sut.runner.execute(spell: makeSpell(silent: true))

        assertContains(sut.terminal.writtenErrors, "err\n")
    }

    @Test func silentFailure_showsExitCode() throws {
        let cap = MockCapturingRunner()
        cap.result = CapturedProcessResult(exitCode: 42)
        let sut = makeSUT(cap)

        try sut.runner.execute(spell: makeSpell(silent: true))

        assertContains(
            sut.terminal.writtenErrors, "✗ test (exit 42)"
        )
    }

    @Test func silentFailure_forwardsExitCode() throws {
        let cap = MockCapturingRunner()
        cap.result = CapturedProcessResult(exitCode: 7)
        let sut = makeSUT(cap)

        let code = try sut.runner.execute(
            spell: makeSpell(silent: true)
        )

        #expect(code == 7)
    }

    // MARK: - US-007C: Buffer overflow

    @Test func overflow_showsWarning() throws {
        let cap = overflowRunner(
            stdout: Array("big\n".utf8)
        )
        let sut = makeSUT(cap)

        try sut.runner.execute(spell: makeSpell(silent: true))

        let hasWarning = sut.terminal.writtenErrors.contains {
            $0.contains("silent mode disabled")
        }
        #expect(hasWarning)
    }

    @Test func overflow_flushesBufferedData() throws {
        let cap = overflowRunner(
            stdout: Array("buffered\n".utf8),
            stderr: Array("errbuf\n".utf8)
        )
        let sut = makeSUT(cap)

        try sut.runner.execute(spell: makeSpell(silent: true))

        assertContains(sut.terminal.written, "buffered\n")
        assertContains(sut.terminal.writtenErrors, "errbuf\n")
    }

    @Test func overflow_restoresCursor() throws {
        let cap = overflowRunner()
        let sut = makeSUT(cap)

        try sut.runner.execute(spell: makeSpell(silent: true))

        #expect(sut.terminal.cursorHidden == false)
    }
}

// MARK: - Helpers

extension SilentRunnerFailureTests {
    struct SUT {
        let runner: SilentRunner
        let terminal: MockTerminal
        let processRunner: MockProcessRunner
    }

    private func makeSUT(_ capturing: MockCapturingRunner) -> SUT {
        let terminal = MockTerminal(
            capabilities: TerminalCapabilities(
                isTTY: true,
                supportsColor: false,
                supportsRawMode: false
            )
        )
        let processRunner = MockProcessRunner()
        let runner = SilentRunner(
            terminal: terminal,
            capturingRunner: capturing,
            scriptExecutor: ScriptExecutor(
                processRunner: processRunner
            )
        )
        return SUT(runner: runner, terminal: terminal, processRunner: processRunner)
    }

    private func overflowRunner(
        stdout: [UInt8] = [],
        stderr: [UInt8] = []
    ) -> MockCapturingRunner {
        let cap = MockCapturingRunner()
        cap.shouldOverflow = true
        cap.overflowStdout = stdout
        cap.overflowStderr = stderr
        return cap
    }

    private func makeSpell(
        silent: Bool
    ) -> PreparedSpell {
        PreparedSpell(
            name: "test",
            resolvedScript: "echo hello",
            resolvedWorkingDir: "/tmp",
            silent: silent,
            manifestPath: "/tmp/spells.yaml"
        )
    }

    private func assertContains(
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
