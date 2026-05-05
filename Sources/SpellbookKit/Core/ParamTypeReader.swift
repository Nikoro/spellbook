enum ParamTypeReader {
    static func read(_ node: YAMLNode) -> ParamType {
        switch node.scalar {
        case "bool", "boolean": return .bool
        case "int", "integer": return .int
        case "double": return .double
        case "num", "number": return .number
        default: return .string
        }
    }
}
