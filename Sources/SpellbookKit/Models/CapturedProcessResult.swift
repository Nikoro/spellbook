public struct CapturedProcessResult: Equatable, Sendable {
    public let exitCode: Int32
    public let stdout: [UInt8]
    public let stderr: [UInt8]
    public let didOverflow: Bool

    public init(
        exitCode: Int32,
        stdout: [UInt8] = [],
        stderr: [UInt8] = [],
        didOverflow: Bool = false
    ) {
        self.exitCode = exitCode
        self.stdout = stdout
        self.stderr = stderr
        self.didOverflow = didOverflow
    }
}
