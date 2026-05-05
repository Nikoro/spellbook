public protocol OutputCapturingRunner {
    @discardableResult
    func runCapturing(
        invocation: ProcessInvocation,
        bufferCap: Int,
        overflowHandler: @escaping @Sendable (_ stdout: [UInt8], _ stderr: [UInt8]) -> Void
    ) throws -> CapturedProcessResult
}
