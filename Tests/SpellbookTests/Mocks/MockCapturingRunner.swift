@testable import SpellbookKit

public final class MockCapturingRunner: OutputCapturingRunner {
    public var result = CapturedProcessResult(exitCode: 0)
    public var shouldOverflow = false
    public var overflowStdout: [UInt8] = []
    public var overflowStderr: [UInt8] = []
    public var errorToThrow: Error?
    public private(set) var invocations: [ProcessInvocation] = []

    public init() {}

    @discardableResult
    public func runCapturing(
        invocation: ProcessInvocation,
        bufferCap: Int,
        overflowHandler: @escaping ([UInt8], [UInt8]) -> Void
    ) throws -> CapturedProcessResult {
        invocations.append(invocation)
        if let error = errorToThrow { throw error }
        if shouldOverflow {
            overflowHandler(overflowStdout, overflowStderr)
            return CapturedProcessResult(
                exitCode: result.exitCode,
                didOverflow: true
            )
        }
        return result
    }
}
