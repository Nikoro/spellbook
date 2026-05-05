public protocol ProcessRunner {
    @discardableResult
    func run(
        executablePath: String,
        arguments: [String],
        environment: [String: String]?,
        workingDirectory: String?
    ) throws -> Int32
}
