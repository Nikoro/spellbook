public enum FuzzyMatcher {
    public static func rank(
        query: String,
        candidates: [String]
    ) -> [RankedCandidate] {
        if query.isEmpty { return emptyQuery(candidates: candidates) }
        let normalized = normalize(query)
        var indexed: [(index: Int, ranked: RankedCandidate)] = []
        for (idx, candidate) in candidates.enumerated() {
            guard let match = match(query: normalized, candidate: candidate) else { continue }
            indexed.append((idx, match))
        }
        indexed.sort { lhs, rhs in
            if lhs.ranked.score != rhs.ranked.score { return lhs.ranked.score > rhs.ranked.score }
            let llen = lhs.ranked.candidate.count
            let rlen = rhs.ranked.candidate.count
            if llen != rlen { return llen < rlen }
            return lhs.index < rhs.index
        }
        return indexed.map(\.ranked)
    }

    private static func emptyQuery(candidates: [String]) -> [RankedCandidate] {
        candidates.map { RankedCandidate(candidate: $0, score: 0, matchedPositions: []) }
    }

    private static func normalize(_ query: String) -> String {
        var stripped = query
        if stripped.hasPrefix("--") {
            stripped.removeFirst(2)
        } else if stripped.hasPrefix("-") {
            stripped.removeFirst(1)
        }
        return stripped.lowercased()
    }

    private static func match(query: String, candidate: String) -> RankedCandidate? {
        let lowered = candidate.lowercased()
        guard let positions = subsequencePositions(query: query, in: lowered) else { return nil }
        let score = FuzzyScorer.score(query: query, candidate: candidate, positions: positions)
        return RankedCandidate(candidate: candidate, score: score, matchedPositions: positions)
    }

    private static func subsequencePositions(
        query: String,
        in haystack: String
    ) -> [Int]? {
        var positions: [Int] = []
        let queryChars = Array(query)
        var queryCursor = 0
        for (idx, char) in haystack.enumerated()
        where queryCursor < queryChars.count && char == queryChars[queryCursor] {
            positions.append(idx)
            queryCursor += 1
        }
        return queryCursor == queryChars.count ? positions : nil
    }
}
