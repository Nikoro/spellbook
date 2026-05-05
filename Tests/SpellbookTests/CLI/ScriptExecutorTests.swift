import Testing
@testable import SpellbookKit

struct ScriptExecutorTests {

    // MARK: - Default shell

    @Test func defaultShell_isBash() throws {
        let runner = MockProcessRunner()
        let executor = ScriptExecutor(processRunner: runner)

        try executor.execute(script: "echo hi")

        let invocation = try #require(runner.invocations.first)
        #expect(invocation.arguments == ["bash", "-c", "echo hi"])
    }

    // MARK: - Custom shell

    @Test func customShell_overridesDefault() throws {
        let runner = MockProcessRunner()
        let executor = ScriptExecutor(processRunner: runner)

        try executor.execute(script: "echo hi", shell: "zsh")

        let invocation = try #require(runner.invocations.first)
        #expect(invocation.arguments == ["zsh", "-c", "echo hi"])
    }

    @Test func shellPath_passedDirectly() throws {
        let runner = MockProcessRunner()
        let executor = ScriptExecutor(processRunner: runner)

        try executor.execute(script: "echo hi", shell: "/bin/sh")

        let invocation = try #require(runner.invocations.first)
        #expect(invocation.arguments == ["/bin/sh", "-c", "echo hi"])
    }

    // MARK: - Executable path

    @Test func usesUsrBinEnv() throws {
        let runner = MockProcessRunner()
        let executor = ScriptExecutor(processRunner: runner)

        try executor.execute(script: "true")

        let invocation = try #require(runner.invocations.first)
        #expect(invocation.executablePath == "/usr/bin/env")
    }

    // MARK: - Exit code

    @Test func exitCode_forwarded() throws {
        let runner = MockProcessRunner()
        runner.exitCode = 42
        let executor = ScriptExecutor(processRunner: runner)

        let code = try executor.execute(script: "false")

        #expect(code == 42)
    }

    // MARK: - Multiline script

    @Test func multilineScript_passedUnmodified() throws {
        let runner = MockProcessRunner()
        let executor = ScriptExecutor(processRunner: runner)
        let script = "set -e\necho one\necho two"

        try executor.execute(script: script)

        let invocation = try #require(runner.invocations.first)
        #expect(invocation.arguments[2] == script)
    }

    // MARK: - Environment and working directory

    @Test func environment_passedThrough() throws {
        let runner = MockProcessRunner()
        let executor = ScriptExecutor(processRunner: runner)
        let env = ["SPELLBOOK_SPELL_NAME": "hello"]

        try executor.execute(script: "true", environment: env)

        let invocation = try #require(runner.invocations.first)
        #expect(invocation.environment == env)
    }

    @Test func workingDirectory_passedThrough() throws {
        let runner = MockProcessRunner()
        let executor = ScriptExecutor(processRunner: runner)

        try executor.execute(script: "pwd", workingDirectory: "/tmp")

        let invocation = try #require(runner.invocations.first)
        #expect(invocation.workingDirectory == "/tmp")
    }

    @Test func noEnvOrCwd_passesNil() throws {
        let runner = MockProcessRunner()
        let executor = ScriptExecutor(processRunner: runner)

        try executor.execute(script: "true")

        let invocation = try #require(runner.invocations.first)
        #expect(invocation.environment == nil)
        #expect(invocation.workingDirectory == nil)
    }

    // MARK: - Launch failure

    @Test func launchFailure_propagatesError() {
        let runner = MockProcessRunner()
        runner.errorToThrow = SpellbookError.scriptLaunchFailed(
            shell: "bash", reason: "No such file or directory"
        )
        let executor = ScriptExecutor(processRunner: runner)

        #expect(throws: SpellbookError.scriptLaunchFailed(
                    shell: "bash", reason: "No such file or directory"
                )) {
            try executor.execute(script: "echo hi")
        }
    }

    @Test func launchFailure_stillRecordsInvocation() {
        let runner = MockProcessRunner()
        runner.errorToThrow = SpellbookError.scriptLaunchFailed(
            shell: "bash", reason: "failed"
        )
        let executor = ScriptExecutor(processRunner: runner)

        _ = try? executor.execute(script: "echo hi")

        #expect(runner.invocations.count == 1)
    }
}
