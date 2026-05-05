import Foundation

public final class FoundationProcessRunner: ProcessRunner {
    public init() {}

    @discardableResult
    public func run(
        executablePath: String,
        arguments: [String],
        environment: [String: String]?,
        workingDirectory: String?
    ) throws -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments

        if let env = environment {
            process.environment = ProcessInfo.processInfo.environment
                .merging(env) { _, new in new }
        }
        if let cwd = workingDirectory {
            process.currentDirectoryURL = URL(fileURLWithPath: cwd)
        }

        process.standardInput = FileHandle.standardInput
        process.standardOutput = FileHandle.standardOutput
        process.standardError = FileHandle.standardError

        do {
            try process.run()
        } catch {
            let shell = arguments.first ?? executablePath
            throw SpellbookError.scriptLaunchFailed(
                shell: shell,
                reason: error.localizedDescription
            )
        }

        process.waitUntilExit()
        return process.terminationStatus
    }
}
