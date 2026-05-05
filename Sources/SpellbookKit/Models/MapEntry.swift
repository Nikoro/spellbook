public struct MapEntry: Equatable, Sendable {
    public let key: String
    public let description: String?
    public let value: YAMLNode

    public init(key: String, description: String? = nil, value: YAMLNode) {
        self.key = key
        self.description = description
        self.value = value
    }
}
