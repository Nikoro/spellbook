public struct ParamShape: Equatable, Sendable {
    public let isRequired: Bool
    public let isPositional: Bool
    public let flags: [String]

    public init(
        isRequired: Bool = false,
        isPositional: Bool = true,
        flags: [String] = []
    ) {
        self.isRequired = isRequired
        self.isPositional = isPositional
        self.flags = flags
    }
}
