public enum ParamType: Equatable, Sendable {
    case string
    case bool
    case int
    case double
    case number

    public var zero: String {
        switch self {
        case .string: return ""
        case .bool: return "false"
        case .int, .double, .number: return "0"
        }
    }
}
