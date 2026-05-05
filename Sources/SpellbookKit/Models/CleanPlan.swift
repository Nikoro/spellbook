public struct CleanPlan: Equatable, Sendable {
    public let wrappersToRemove: [String]
    public let stateNamesToForget: [String]
    public let clearProject: Bool

    public init(
        wrappersToRemove: [String],
        stateNamesToForget: [String],
        clearProject: Bool = false
    ) {
        self.wrappersToRemove = wrappersToRemove
        self.stateNamesToForget = stateNamesToForget
        self.clearProject = clearProject
    }
}
