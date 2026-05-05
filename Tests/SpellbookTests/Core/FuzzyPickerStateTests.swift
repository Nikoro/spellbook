import Testing
@testable import SpellbookKit

struct FuzzyPickerStateTests {

    // MARK: initial state

    @Test func emptyQuery_showsAllCandidates() {
        let state = FuzzyPickerState(candidates: ["alpha", "beta", "gamma"])
        #expect(state.visible.map(\.candidate) == ["alpha", "beta", "gamma"])
        #expect(state.selectedIndex == 0)
        #expect(state.query.isEmpty)
    }

    // MARK: typing

    @Test func typingCharacter_narrowsCandidates() {
        var state = FuzzyPickerState(candidates: ["alpha", "one", "gamma"])
        state.apply(.char("a"))
        let visible = state.visible.map(\.candidate)
        #expect(visible.contains("alpha"))
        #expect(visible.contains("gamma"))
        #expect(visible.contains("one") == false)
    }

    @Test func backspace_restoresFilter() {
        var state = FuzzyPickerState(candidates: ["alpha", "beta"])
        state.apply(.char("a"))
        state.apply(.backspace)
        #expect(state.query.isEmpty)
        #expect(state.visible.map(\.candidate) == ["alpha", "beta"])
    }

    @Test func typingKeepsTopRankedHighlighted_whenUserHasNotNavigated() {
        var state = FuzzyPickerState(candidates: ["staging", "prod", "dev"])
        state.apply(.char("p"))
        #expect(state.visible.first?.candidate == "prod")
        #expect(state.selectedIndex == 0)
    }

    // MARK: digit direct-select vs query

    @Test func digitDirectSelects_whenQueryEmpty() {
        var state = FuzzyPickerState(candidates: ["a", "b", "c"])
        let outcome = state.apply(.digit(2))
        #expect(outcome == .accepted(1))
    }

    @Test func digitGoesToQuery_whenQueryNonEmpty() {
        var state = FuzzyPickerState(candidates: ["a1", "b2", "c"])
        state.apply(.char("a"))
        let outcome = state.apply(.digit(1))
        #expect(outcome == .pending)
        #expect(state.query == "a1")
    }

    // MARK: ESC behavior

    @Test func escClearsFilter_whenQueryNonEmpty() {
        var state = FuzzyPickerState(candidates: ["alpha", "beta"])
        state.apply(.char("a"))
        let outcome = state.apply(.cancel)
        #expect(outcome == .pending)
        #expect(state.query.isEmpty)
    }

    @Test func escClosesPicker_whenQueryEmpty() {
        var state = FuzzyPickerState(candidates: ["alpha", "beta"])
        let outcome = state.apply(.cancel)
        #expect(outcome == .cancelled)
    }

    // MARK: navigation & confirm

    @Test func navigationFollowsFilteredList() {
        var state = FuzzyPickerState(candidates: ["alpha", "one", "gamma"])
        state.apply(.char("a"))
        state.apply(.moveDown)
        let outcome = state.apply(.confirm)
        if case .accepted(let idx) = outcome {
            // Visible: alpha, gamma. Move down from 0 → 1 (gamma).
            #expect(state.candidates[idx] == "gamma")
        } else {
            #expect(Bool(false), "expected accepted")
        }
    }

    @Test func confirm_onEmptyResult_doesNothing() {
        var state = FuzzyPickerState(candidates: ["alpha", "beta"])
        state.apply(.char("z"))
        let outcome = state.apply(.confirm)
        #expect(outcome == .pending)
    }

    // MARK: matched-position highlights

    @Test func visibleCandidatesCarryMatchedPositions() {
        var state = FuzzyPickerState(candidates: ["no-cache", "verbose"])
        state.apply(.char("n"))
        state.apply(.char("c"))
        let top = state.visible.first
        #expect(top?.candidate == "no-cache")
        #expect(top?.matchedPositions.isEmpty == false)
    }

    // MARK: flag-query dash-strip

    @Test func flagCandidates_leadingDashStrippedFromQuery() {
        var state = FuzzyPickerState(candidates: ["--no-cache", "--verbose"])
        state.apply(.char("-"))
        state.apply(.char("-"))
        state.apply(.char("n"))
        state.apply(.char("c"))
        #expect(state.visible.first?.candidate == "--no-cache")
    }
}
