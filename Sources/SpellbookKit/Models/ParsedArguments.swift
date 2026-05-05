public struct ParsedArguments: Equatable, Sendable {
    public let values: [String: String]
    public let passthrough: [String]

    public init(values: [String: String] = [:], passthrough: [String] = []) {
        self.values = values
        self.passthrough = passthrough
    }
}
