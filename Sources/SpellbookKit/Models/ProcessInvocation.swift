public struct ProcessInvocation: Equatable, Sendable {
    public let executablePath: String
    public let arguments: [String]
    public let environment: [String: String]?
    public let workingDirectory: String?

    public init(
        executablePath: String,
        arguments: [String],
        environment: [String: String]? = nil,
        workingDirectory: String? = nil
    ) {
        self.executablePath = executablePath
        self.arguments = arguments
        self.environment = environment
        self.workingDirectory = workingDirectory
    }
}
