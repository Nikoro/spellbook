public struct SpellBody: Equatable, Sendable {
    public let script: String?
    public let params: [ParamDefinition]
    public let switchBranches: SwitchDefinition?

    public init(
        script: String? = nil,
        params: [ParamDefinition] = [],
        switchBranches: SwitchDefinition? = nil
    ) {
        self.script = script
        self.params = params
        self.switchBranches = switchBranches
    }

    public static let empty = SpellBody()
}
