public struct RankedCandidate: Equatable, Sendable {
    public let candidate: String
    public let score: Int
    public let matchedPositions: [Int]

    public init(candidate: String, score: Int, matchedPositions: [Int]) {
        self.candidate = candidate
        self.score = score
        self.matchedPositions = matchedPositions
    }
}
