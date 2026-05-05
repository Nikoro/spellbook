public struct SwitchDefinition: Equatable, Sendable {
    public let options: [SwitchOptionDefinition]
    public let defaultBranch: DefaultBranch

    public init(options: [SwitchOptionDefinition], defaultBranch: DefaultBranch = .none) {
        self.options = options
        self.defaultBranch = defaultBranch
    }
}
