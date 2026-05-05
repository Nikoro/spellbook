@testable import SpellbookKit

public final class MockProcessRunner: ProcessRunner {
    public struct Invocation: Equatable {
        public let executablePath: String
        public let arguments: [String]
        public let environment: [String: String]?
        public let workingDirectory: String?
    }

    public var invocations: [Invocation] = []
    public var exitCode: Int32 = 0
    public var errorToThrow: Error?

    public init() {}

    @discardableResult
    public func run(
        executablePath: String,
        arguments: [String],
        environment: [String: String]?,
        workingDirectory: String?
    ) throws -> Int32 {
        invocations.append(Invocation(
            executablePath: executablePath,
            arguments: arguments,
            environment: environment,
            workingDirectory: workingDirectory
        ))
        if let error = errorToThrow { throw error }
        return exitCode
    }
}
