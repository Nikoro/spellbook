struct YAMLQuoteScanner {
    enum Mode: Equatable {
        case none, single, double
    }

    private(set) var mode: Mode = .none
    private var escape = false

    init() {}

    var isOpen: Bool { mode != .none }

    mutating func consume(_ char: Character) -> Bool {
        if escape { escape = false; return true }
        switch mode {
        case .double:
            return consumeDouble(char)
        case .single:
            if char == "'" { mode = .none }
            return true
        case .none:
            return consumeOpen(char)
        }
    }

    private mutating func consumeDouble(_ char: Character) -> Bool {
        if char == "\\" { escape = true; return true }
        if char == "\"" { mode = .none }
        return true
    }

    private mutating func consumeOpen(_ char: Character) -> Bool {
        if char == "\"" { mode = .double; return true }
        if char == "'" { mode = .single; return true }
        return false
    }
}
