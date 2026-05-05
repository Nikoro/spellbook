public enum YAMLNode: Equatable, Sendable {
    case scalar(String)
    case map([MapEntry])
    case sequence([YAMLNode])
    case null

    public var scalar: String? {
        if case .scalar(let value) = self { return value }
        return nil
    }

    public var map: [MapEntry]? {
        if case .map(let entries) = self { return entries }
        return nil
    }

    public var sequence: [YAMLNode]? {
        if case .sequence(let items) = self { return items }
        return nil
    }

    public var isNull: Bool {
        if case .null = self { return true }
        return false
    }
}
