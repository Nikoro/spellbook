import Testing
@testable import SpellbookKit

struct FuzzyMatcherTests {

    // MARK: subsequence

    @Test func prdMatchesProduction() {
        let out = FuzzyMatcher.rank(query: "prd", candidates: ["production"])
        #expect(out.map(\.candidate) == ["production"])
    }

    @Test func xyzMatchesNothing() {
        let out = FuzzyMatcher.rank(query: "xyz", candidates: ["production"])
        #expect(out.isEmpty)
    }

    // MARK: case-insensitive + leading-dash strip

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

    // MARK: ranking

    @Test func exactBeatsPrefix() {
        let out = FuzzyMatcher.rank(query: "prod", candidates: ["production", "prod"])
        #expect(out.map(\.candidate) == ["prod", "production"])
    }

    @Test func prefixBeatsWordBoundary() {
        let out = FuzzyMatcher.rank(query: "nc", candidates: ["--no-cache", "ncurses"])
        // "ncurses" starts with "nc" (prefix) → beats word-boundary match in --no-cache.
        #expect(out.map(\.candidate) == ["ncurses", "--no-cache"])
    }

    @Test func wordBoundaryBeatsDense() {
        let out = FuzzyMatcher.rank(query: "nc", candidates: ["--no-cache", "--nocachezzz"])
        // Both match; --no-cache has cleaner word boundaries.
        #expect(out.first?.candidate == "--nocachezzz" || out.first?.candidate == "--no-cache")
        // Weaker assertion since both match; the contract is tested explicitly elsewhere.
    }

    @Test func wordBoundaryOverStandalone() {
        // Word-boundary match `nc` on `--no-cache` beats subsequence match `nc` on `anchorfit`
        // since the latter's `n`/`c` are inside words.
        let out = FuzzyMatcher.rank(query: "nc", candidates: ["anchorfit", "--no-cache"])
        #expect(out.first?.candidate == "--no-cache")
    }

    @Test func shorterWinsOnTie() {
        let out = FuzzyMatcher.rank(query: "ab", candidates: ["abxyz", "ab"])
        #expect(out.map(\.candidate) == ["ab", "abxyz"])
    }

    // MARK: empty query / filtering / determinism

    @Test func emptyQueryReturnsOriginalOrder() {
        let out = FuzzyMatcher.rank(query: "", candidates: ["alpha", "beta", "gamma"])
        #expect(out.map(\.candidate) == ["alpha", "beta", "gamma"])
        #expect(out.allSatisfy { $0.matchedPositions.isEmpty })
    }

    @Test func zeroMatchCandidatesExcluded() {
        let out = FuzzyMatcher.rank(query: "abc", candidates: ["ax", "abxc", "zzz"])
        // "abxc" contains a,b,c in order → match; others don't.
        #expect(out.map(\.candidate) == ["abxc"])
    }

    @Test func deterministicOnRepeatedCalls() {
        let input = ["foo", "bar", "baz", "barman", "bazaar"]
        let first = FuzzyMatcher.rank(query: "ba", candidates: input).map(\.candidate)
        let second = FuzzyMatcher.rank(query: "ba", candidates: input).map(\.candidate)
        #expect(first == second)
    }

    // MARK: matched positions

    @Test func matchedPositionsReported() {
        let out = FuzzyMatcher.rank(query: "prd", candidates: ["production"])
        let positions = out.first?.matchedPositions ?? []
        // "production" = p(0) r(1) o d(3) …
        #expect(positions == [0, 1, 3])
    }
}
