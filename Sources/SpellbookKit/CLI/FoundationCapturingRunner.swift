import Foundation

public final class FoundationCapturingRunner: OutputCapturingRunner {
    public init() {}

    @discardableResult
    public func runCapturing(
        invocation: ProcessInvocation,
        bufferCap: Int,
        overflowHandler: @escaping @Sendable ([UInt8], [UInt8]) -> Void
    ) throws -> CapturedProcessResult {
        let process = makeProcess(from: invocation)
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        process.standardInput = FileHandle.standardInput

        try launchProcess(process, invocation: invocation)

        let collector = PipeCollector(
            stdoutHandle: stdoutPipe.fileHandleForReading,
            stderrHandle: stderrPipe.fileHandleForReading,
            bufferCap: bufferCap,
            overflowHandler: overflowHandler
        )
        collector.start()
        process.waitUntilExit()
        collector.wait()

        return CapturedProcessResult(
            exitCode: process.terminationStatus,
            stdout: collector.stdoutBytes,
            stderr: collector.stderrBytes,
            didOverflow: collector.didOverflow
        )
    }
}

private func makeProcess(
    from invocation: ProcessInvocation
) -> Process {
    let process = Process()
    process.executableURL = URL(
        fileURLWithPath: invocation.executablePath
    )
    process.arguments = invocation.arguments
    if let env = invocation.environment {
        process.environment = ProcessInfo.processInfo.environment
            .merging(env) { _, new in new }
    }
    if let cwd = invocation.workingDirectory {
        process.currentDirectoryURL = URL(fileURLWithPath: cwd)
    }
    return process
}

private func launchProcess(
    _ process: Process,
    invocation: ProcessInvocation
) throws {
    do {
        try process.run()
    } catch {
        let shell = invocation.arguments.first
            ?? invocation.executablePath
        throw SpellbookError.scriptLaunchFailed(
            shell: shell,
            reason: error.localizedDescription
        )
    }
}
