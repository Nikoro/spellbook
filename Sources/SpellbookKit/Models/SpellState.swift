public struct SpellState: Codable, Equatable, Sendable {
    public let hash: String
    public let wrapper: String
    public let origin: String

    public init(hash: String, wrapper: String, origin: String) {
        self.hash = hash
        self.wrapper = wrapper
        self.origin = origin
    }
}
