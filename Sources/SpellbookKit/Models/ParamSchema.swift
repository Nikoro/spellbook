public struct ParamSchema: Equatable, Sendable {
    public let type: ParamType
    public let values: [String]
    public let defaultValue: String?

    public init(
        type: ParamType = .string,
        values: [String] = [],
        defaultValue: String? = nil
    ) {
        self.type = type
        self.values = values
        self.defaultValue = defaultValue
    }
}
