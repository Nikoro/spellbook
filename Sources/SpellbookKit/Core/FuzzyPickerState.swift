public struct FuzzyPickerState {
    public let candidates: [String]
    public private(set) var query: String = ""
    public private(set) var visible: [RankedCandidate]
    public private(set) var selectedIndex: Int = 0
    private var userNavigated = false

    public init(candidates: [String]) {
        self.candidates = candidates
        self.visible = FuzzyMatcher.rank(query: "", candidates: candidates)
    }

    @discardableResult
    public mutating func apply(_ input: FuzzyPickerInput) -> FuzzyPickerOutcome {
        switch input {
        case .char(let char):
            appendToQuery(String(char))
            return .pending
        case .digit(let value):
            return handleDigit(value)
        case .backspace:
            if !query.isEmpty {
                query.removeLast()
                recomputeVisible()
            }
            return .pending
        case .moveUp:
            moveSelection(by: -1)
            return .pending
        case .moveDown:
            moveSelection(by: 1)
            return .pending
        case .confirm:
            return handleConfirm()
        case .cancel:
            if query.isEmpty { return .cancelled }
            query = ""
            recomputeVisible()
            return .pending
        }
    }

    private mutating func handleDigit(_ value: Int) -> FuzzyPickerOutcome {
        if query.isEmpty { return directSelect(digit: value) }
        appendToQuery(String(value))
        return .pending
    }

    private func directSelect(digit: Int) -> FuzzyPickerOutcome {
        guard digit >= 1, digit <= candidates.count else { return .pending }
        return .accepted(digit - 1)
    }

    private mutating func handleConfirm() -> FuzzyPickerOutcome {
        guard !visible.isEmpty, selectedIndex < visible.count else { return .pending }
        let chosen = visible[selectedIndex].candidate
        guard let originalIndex = candidates.firstIndex(of: chosen) else {
            return .pending
        }
        return .accepted(originalIndex)
    }

    private mutating func appendToQuery(_ string: String) {
        query.append(string)
        recomputeVisible()
    }

    private mutating func recomputeVisible() {
        visible = FuzzyMatcher.rank(query: query, candidates: candidates)
        if !userNavigated {
            selectedIndex = 0
        } else if selectedIndex >= visible.count {
            selectedIndex = max(0, visible.count - 1)
        }
    }

    private mutating func moveSelection(by delta: Int) {
        guard !visible.isEmpty else { return }
        userNavigated = true
        let next = selectedIndex + delta
        if next < 0 {
            selectedIndex = visible.count - 1
        } else if next >= visible.count {
            selectedIndex = 0
        } else {
            selectedIndex = next
        }
    }
}
