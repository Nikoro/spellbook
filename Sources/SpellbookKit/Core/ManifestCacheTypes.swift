enum ManifestCacheTypes {
    static func paramTypeCode(_ type: ParamType) -> UInt8 {
        switch type {
        case .string: return 0
        case .bool: return 1
        case .int: return 2
        case .double: return 3
        case .number: return 4
        }
    }

    static func paramType(for code: UInt8) -> ParamType? {
        switch code {
        case 0: return .string
        case 1: return .bool
        case 2: return .int
        case 3: return .double
        case 4: return .number
        default: return nil
        }
    }
}
