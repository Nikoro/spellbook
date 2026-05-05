public struct YAMLLine: Equatable, Sendable {
    public enum Kind: Equatable, Sendable {
        case mapping(content: String, description: String?)
        case blockScalarBody(raw: String)
    }

    public let number: Int
    public let indent: Int
    public let kind: Kind

    public init(number: Int, indent: Int, kind: Kind) {
        self.number = number
        self.indent = indent
        self.kind = kind
    }
}
