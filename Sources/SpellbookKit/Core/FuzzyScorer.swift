enum FuzzyScorer {
    private static let exactBonus = 10_000
    private static let prefixBonus = 5_000
    private static let wordBoundaryBonus = 200
    private static let consecutiveBonus = 50

    static func score(
        query: String,
        candidate: String,
        positions: [Int]
    ) -> Int {
        var total = 0
        let queryLower = query.lowercased()
        let candidateLower = candidate.lowercased()
        let candidateStripped = stripLeadingDashes(candidateLower)
        if candidateLower == queryLower || candidateStripped == queryLower {
            total += exactBonus
        }
        if candidateLower.hasPrefix(queryLower) || candidateStripped.hasPrefix(queryLower) {
            total += prefixBonus
        }
        let chars = Array(candidate)
        total += wordBoundaryScore(chars: chars, positions: positions)
        total += consecutiveScore(positions: positions)
        return total
    }

    private static func stripLeadingDashes(_ str: String) -> String {
        var copy = str
        if copy.hasPrefix("--") { copy.removeFirst(2) } else if copy.hasPrefix("-") {
            copy.removeFirst(1)
        }
        return copy
    }

    private static func wordBoundaryScore(
        chars: [Character],
        positions: [Int]
    ) -> Int {
        var score = 0
        for position in positions where isWordBoundary(chars: chars, at: position) {
            score += wordBoundaryBonus
        }
        return score
    }

    private static func consecutiveScore(positions: [Int]) -> Int {
        guard positions.count > 1 else { return 0 }
        var runs = 0
        for index in 1..<positions.count where positions[index] == positions[index - 1] + 1 {
            runs += 1
        }
        return runs * consecutiveBonus
    }

    private static func isWordBoundary(chars: [Character], at position: Int) -> Bool {
        if position == 0 { return true }
        let prev = chars[position - 1]
        let current = chars[position]
        if prev == "-" || prev == "_" || prev == " " { return true }
        if prev.isLowercase && current.isUppercase { return true }
        return false
    }
}
