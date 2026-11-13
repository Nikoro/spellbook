import Testing
@testable import SpellbookKit

struct FuzzyMatcherTests {

    @Test func prdMatchesProduction() {
        let out = FuzzyMatcher.rank(query: "prd", candidates: ["production"])
        #expect(out.map(\.candidate) == ["production"])
    }

    @Test func xyzMatchesNothing() {
        let out = FuzzyMatcher.rank(query: "xyz", candidates: ["production"])
        #expect(out.isEmpty)
    }

    @Test func caseInsensitive() {
        let out = FuzzyMatcher.rank(query: "PRD", candidates: ["production"])
        #expect(out.map(\.candidate) == ["production"])
    }

    @Test func leadingDoubleDashStripped_forFlagCandidates() {
        let out = FuzzyMatcher.rank(query: "--nc", candidates: ["--no-cache", "--verbose"])
        #expect(out.first?.candidate == "--no-cache")
    }

    @Test func leadingSingleDashStripped() {
        let out = FuzzyMatcher.rank(query: "-nc", candidates: ["--no-cache"])
        #expect(out.first?.candidate == "--no-cache")
    }

    @Test func exactBeatsPrefix() {
        let out = FuzzyMatcher.rank(query: "prod", candidates: ["production", "prod"])
        #expect(out.map(\.candidate) == ["prod", "production"])
    }

    @Test func prefixBeatsWordBoundary() {
        let out = FuzzyMatcher.rank(query: "nc", candidates: ["--no-cache", "ncurses"])
        #expect(out.map(\.candidate) == ["ncurses", "--no-cache"])
    }

    @Test func wordBoundaryOverStandalone() {
        let out = FuzzyMatcher.rank(query: "nc", candidates: ["anchorfit", "--no-cache"])
        #expect(out.first?.candidate == "--no-cache")
    }

    @Test func shorterWinsOnTie() {
        let out = FuzzyMatcher.rank(query: "ab", candidates: ["abxyz", "ab"])
        #expect(out.map(\.candidate) == ["ab", "abxyz"])
    }

    @Test func emptyQueryReturnsOriginalOrder() {
        let out = FuzzyMatcher.rank(query: "", candidates: ["alpha", "beta", "gamma"])
        #expect(out.map(\.candidate) == ["alpha", "beta", "gamma"])
        #expect(out.allSatisfy { $0.matchedPositions.isEmpty })
    }

    @Test func zeroMatchCandidatesExcluded() {
        let out = FuzzyMatcher.rank(query: "abc", candidates: ["ax", "abxc", "zzz"])
        #expect(out.map(\.candidate) == ["abxc"])
    }

    @Test func deterministicOnRepeatedCalls() {
        let input = ["foo", "bar", "baz", "barman", "bazaar"]
        let first = FuzzyMatcher.rank(query: "ba", candidates: input).map(\.candidate)
        let second = FuzzyMatcher.rank(query: "ba", candidates: input).map(\.candidate)
        #expect(first == second)
    }

    @Test func matchedPositionsReported() {
        let out = FuzzyMatcher.rank(query: "prd", candidates: ["production"])
        let positions = out.first?.matchedPositions ?? []
        #expect(positions == [0, 1, 3])
    }
}
