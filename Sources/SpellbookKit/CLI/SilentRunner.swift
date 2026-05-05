public struct SilentRunner {
    private static let bufferCap = 1_048_576

    private let terminal: TerminalProtocol
    private let capturingRunner: OutputCapturingRunner
    private let scriptExecutor: ScriptExecutor

    public init(
        terminal: TerminalProtocol,
        capturingRunner: OutputCapturingRunner,
        scriptExecutor: ScriptExecutor
    ) {
        self.terminal = terminal
        self.capturingRunner = capturingRunner
        self.scriptExecutor = scriptExecutor
    }

    @discardableResult
    public func execute(
        spell: PreparedSpell,
        label: String? = nil
    ) throws -> Int32 {
        guard spell.silent,
              terminal.capabilities.isTTY else {
            return try executePassthrough(spell)
        }
        return try executeSilent(spell, label: label)
    }
}

// MARK: - Passthrough (non-TTY or non-silent)

extension SilentRunner {
    private func executePassthrough(
        _ spell: PreparedSpell
    ) throws -> Int32 {
        try scriptExecutor.execute(
            script: spell.resolvedScript,
            shell: spell.shell,
            environment: spell.environment,
            workingDirectory: spell.resolvedWorkingDir
        )
    }
}

// MARK: - Silent TTY execution

extension SilentRunner {
    private func executeSilent(
        _ spell: PreparedSpell,
        label: String?
    ) throws -> Int32 {
        let displayLabel = label ?? spell.name
        terminal.hideCursor()
        terminal.clearLine()
        terminal.write("\u{2807} \(displayLabel)")

        let result: CapturedProcessResult
        let overflowSink = OverflowSink(terminal: terminal)

        do {
            result = try capturingRunner.runCapturing(
                invocation: invocation(for: spell),
                bufferCap: Self.bufferCap,
                overflowHandler: { stdout, stderr in
                    overflowSink.handle(stdout: stdout, stderr: stderr)
                }
            )
        } catch {
            terminal.clearLine()
            terminal.showCursor()
            throw error
        }

        if overflowSink.didFlush {
            return result.exitCode
        }
        presentResult(result, label: displayLabel)
        return result.exitCode
    }

    private func invocation(
        for spell: PreparedSpell
    ) -> ProcessInvocation {
        let shell = spell.shell ?? ShellDefaults.shell
        return ProcessInvocation(
            executablePath: "/usr/bin/env",
            arguments: [shell, "-c", spell.resolvedScript],
            environment: spell.environment,
            workingDirectory: spell.resolvedWorkingDir
        )
    }
}

// MARK: - Result presentation

extension SilentRunner {
    private func presentResult(
        _ result: CapturedProcessResult,
        label: String
    ) {
        terminal.clearLine()
        terminal.showCursor()

        if result.exitCode == 0 {
            terminal.writeLine("\u{2713} \(label)")
            return
        }
        terminal.writeError(
            "\u{2717} \(label) (exit \(result.exitCode))"
        )
        if let text = Self.asString(result.stdout) { terminal.write(text) }
        if let text = Self.asString(result.stderr) { terminal.writeError(text) }
    }

    private static func asString(_ bytes: [UInt8]) -> String? {
        guard !bytes.isEmpty else { return nil }
        return String(bytes: bytes, encoding: .utf8)
    }
}
