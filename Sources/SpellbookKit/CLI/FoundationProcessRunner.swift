import Foundation
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

public final class FoundationProcessRunner: ProcessRunner {
    public init() {}

    @discardableResult
    public func run(
        executablePath: String,
        arguments: [String],
        environment: [String: String]?,
        workingDirectory: String?
    ) throws -> Int32 {
        if let workingDirectory, chdir(workingDirectory) != 0 {
            throw launchError(executablePath: executablePath, arguments: arguments)
        }

        var argumentPointers = makePointers([executablePath] + arguments)
        var environmentPointers = makePointers(resolvedEnvironment(overrides: environment))
        defer {
            releasePointers(argumentPointers)
            releasePointers(environmentPointers)
        }

        _ = executablePath.withCString { executable in
            argumentPointers.withUnsafeMutableBufferPointer { argumentBuffer in
                environmentPointers.withUnsafeMutableBufferPointer { environmentBuffer in
                    execve(executable, argumentBuffer.baseAddress, environmentBuffer.baseAddress)
                }
            }
        }
        throw launchError(executablePath: executablePath, arguments: arguments)
    }

    private func resolvedEnvironment(overrides: [String: String]?) -> [String] {
        let current = ProcessInfo.processInfo.environment
        let merged = overrides.map { current.merging($0) { _, new in new } } ?? current
        return merged.map { "\($0.key)=\($0.value)" }
    }

    private func makePointers(_ values: [String]) -> [UnsafeMutablePointer<CChar>?] {
        values.map { value in value.withCString { strdup($0) } } + [nil]
    }

    private func releasePointers(_ pointers: [UnsafeMutablePointer<CChar>?]) {
        for case let pointer? in pointers {
            free(pointer)
        }
    }

    private func launchError(executablePath: String, arguments: [String]) -> SpellbookError {
        SpellbookError.scriptLaunchFailed(
            shell: arguments.first ?? executablePath,
            reason: String(cString: strerror(errno))
        )
    }
}
