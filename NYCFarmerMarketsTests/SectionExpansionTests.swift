import Testing
@testable import NYCFarmerMarkets

// MARK: - Deterministic random generation (no property-testing library available)

/// Small seeded SplitMix64 generator so every run produces the same inputs.
private struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

private enum Pools {
    static let boroughs = [
        "Manhattan", "Brooklyn", "Queens", "Bronx", "Staten Island",
        "", "  ", "New  York", "Île-de-Ré", "Borough/With:Odd#Chars", "🍎 Orchard",
    ]
    static let emptyQueries = ["", " ", "   ", "\t", "\n", " \t\n "]
    static let nonEmptyQueries = ["a", " a ", "Brooklyn", "  mixed Case  ", "zzzzzz", "Staten Island", "é", "\tx\n"]
    static var anyQueries: [String] { emptyQueries + nonEmptyQueries }
}

private let iterations = 150

private extension SplitMix64 {
    mutating func pick<T>(_ pool: [T]) -> T {
        pool[Int.random(in: 0..<pool.count, using: &self)]
    }

    mutating func randomToggles(count: Int, queries: [String]) -> [(String, String)] {
        (0..<count).map { _ in (pick(Pools.boroughs), pick(queries)) }
    }
}

private func apply(_ toggles: [(String, String)], to state: inout SectionExpansionState) {
    for (borough, query) in toggles {
        state.toggle(borough, query: query)
    }
}

// MARK: - Tests

struct SectionExpansionTests {

    // Feature: splash-screen-collapsible-boroughs, Property 3: Sections start collapsed
    // Validates: Requirements 6.1, 6.6
    @Test func freshStateHasEverythingCollapsed() {
        var rng = SplitMix64(seed: 3)
        for _ in 0..<iterations {
            let state = SectionExpansionState()
            let borough = rng.pick(Pools.boroughs)
            let query = rng.pick(Pools.emptyQueries)
            #expect(!state.isExpanded(borough, query: query))
        }
    }

    // Feature: splash-screen-collapsible-boroughs, Property 4: Toggling twice restores the state
    // Validates: Requirements 6.2, 6.3, 7.4
    @Test func togglingTwiceRestoresAndOnceInverts() {
        var rng = SplitMix64(seed: 4)
        for _ in 0..<iterations {
            var state = SectionExpansionState()
            let priorCount = Int.random(in: 0...12, using: &rng)
            apply(rng.randomToggles(count: priorCount, queries: Pools.anyQueries), to: &state)

            let borough = rng.pick(Pools.boroughs)
            let query = rng.pick(Pools.anyQueries)
            let original = state.isExpanded(borough, query: query)

            state.toggle(borough, query: query)
            #expect(state.isExpanded(borough, query: query) == !original)

            state.toggle(borough, query: query)
            #expect(state.isExpanded(borough, query: query) == original)
        }
    }

    // Feature: splash-screen-collapsible-boroughs, Property 5: Search auto-expands untouched sections
    // Validates: Requirements 7.1
    @Test func searchExpandsSectionsWithoutOverrides() {
        var rng = SplitMix64(seed: 5)
        for _ in 0..<iterations {
            var state = SectionExpansionState()
            // Only toggle while not searching, so there are no search overrides.
            let count = Int.random(in: 0...12, using: &rng)
            apply(rng.randomToggles(count: count, queries: Pools.emptyQueries), to: &state)

            let borough = rng.pick(Pools.boroughs)
            let query = rng.pick(Pools.nonEmptyQueries)
            #expect(state.isExpanded(borough, query: query))
        }
    }

    // Feature: splash-screen-collapsible-boroughs, Property 7: Clearing a search restores the earlier expansion state
    // Validates: Requirements 7.3
    @Test func clearingSearchRestoresEarlierExpansion() {
        var rng = SplitMix64(seed: 7)
        for _ in 0..<iterations {
            var state = SectionExpansionState()
            let before = Int.random(in: 0...12, using: &rng)
            apply(rng.randomToggles(count: before, queries: Pools.emptyQueries), to: &state)

            let expected = Pools.boroughs.map { state.isExpanded($0, query: "") }

            let during = Int.random(in: 0...12, using: &rng)
            apply(rng.randomToggles(count: during, queries: Pools.nonEmptyQueries), to: &state)
            state.endSearch()

            for (borough, wasExpanded) in zip(Pools.boroughs, expected) {
                #expect(state.isExpanded(borough, query: "") == wasExpanded)
            }
        }
    }

    // MARK: Examples

    // Validates: Requirements 7.3, 7.4
    @Test func searchCollapseThenClearStaysCollapsedIfCollapsedBefore() {
        var state = SectionExpansionState()
        #expect(state.isExpanded("Queens", query: "que"))
        state.toggle("Queens", query: "que")
        #expect(!state.isExpanded("Queens", query: "que"))
        state.endSearch()
        #expect(!state.isExpanded("Queens", query: ""))
    }

    // Validates: Requirements 6.2, 7.3
    @Test func manualExpandThenSearchCollapseThenClearIsExpanded() {
        var state = SectionExpansionState()
        state.toggle("Staten Island", query: "")
        #expect(state.isExpanded("Staten Island", query: ""))
        state.toggle("Staten Island", query: "staten")
        #expect(!state.isExpanded("Staten Island", query: "staten"))
        state.endSearch()
        #expect(state.isExpanded("Staten Island", query: ""))
    }

    // Validates: Requirements 6.6, 9.4
    @Test func whitespaceOnlyQueryIsNotSearching() {
        #expect(!SectionExpansionState.isSearching("  "))
        #expect(!SectionExpansionState.isSearching(""))
        #expect(SectionExpansionState.isSearching(" a "))
    }
}
