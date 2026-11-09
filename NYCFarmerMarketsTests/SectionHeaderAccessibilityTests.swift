import Testing
@testable import NYCFarmerMarkets

/// Small deterministic SplitMix64 generator so property runs are reproducible.
private struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

private let boroughCharacterPool: [Character] = Array(
    "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789   -'.éüñßøå漢字🍎"
)

private func randomBorough(using rng: inout SeededGenerator) -> String {
    let length = Int.random(in: 0...24, using: &rng)
    var result = ""
    for _ in 0..<length {
        result.append(boroughCharacterPool.randomElement(using: &rng)!)
    }
    return result
}

private let iterations = 150

struct SectionHeaderAccessibilityTests {

    // Feature: splash-screen-collapsible-boroughs, Property 8: Section header accessibility text is consistent with its state
    // Validates: Requirements 8.2, 8.3, 8.4
    @Test func property8_accessibilityTextMatchesState() {
        var rng = SeededGenerator(seed: 8)
        for _ in 0..<iterations {
            let borough = randomBorough(using: &rng)
            let count = Int.random(in: 0...500, using: &rng)
            let isExpanded = Bool.random(using: &rng)

            #expect(SectionHeaderAccessibility.label(borough: borough, count: count) == "\(borough), \(count) markets")
            #expect(SectionHeaderAccessibility.value(isExpanded: isExpanded) == (isExpanded ? "Expanded" : "Collapsed"))
            #expect(SectionHeaderAccessibility.hint(isExpanded: isExpanded) == (isExpanded ? "Double tap to collapse" : "Double tap to expand"))
        }
    }

    // Feature: splash-screen-collapsible-boroughs, Property 9: Section header identifier has no spaces and encodes the borough
    // Validates: Requirements 8.5
    @Test func property9_identifierHasNoSpacesAndEncodesBorough() {
        let prefix = "section-header-"
        var rng = SeededGenerator(seed: 9)
        for _ in 0..<iterations {
            let borough = randomBorough(using: &rng)
            let id = SectionHeaderAccessibility.identifier(borough: borough)
            let expectedSuffix = String(borough.map { $0 == " " ? "-" : $0 })

            #expect(id == prefix + expectedSuffix)
            #expect(id.hasPrefix(prefix))
            #expect(!id.dropFirst(prefix.count).contains(" "))
            #expect(!prefix.contains(" "))
        }
    }

    @Test func identifierExamples() {
        #expect(SectionHeaderAccessibility.identifier(borough: "Staten Island") == "section-header-Staten-Island")
        #expect(SectionHeaderAccessibility.identifier(borough: "Manhattan") == "section-header-Manhattan")
    }

    @Test func labelExampleForSingleMarket() {
        #expect(SectionHeaderAccessibility.label(borough: "Brooklyn", count: 1) == "Brooklyn, 1 markets")
    }
}
