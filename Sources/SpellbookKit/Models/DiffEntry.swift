public struct DiffEntry: Equatable, Sendable {
    public enum Kind: Equatable, Sendable {
        case added
        case changed
        case removed
    }

    public let name: String
    public let kind: Kind
    public let origin: String?

    public init(name: String, kind: Kind, origin: String? = nil) {
        self.name = name
        self.kind = kind
        self.origin = origin
    }
}
