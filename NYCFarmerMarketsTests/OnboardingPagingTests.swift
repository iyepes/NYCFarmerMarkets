import Testing
@testable import NYCFarmerMarkets

struct OnboardingPagingTests {
    @Test func movesForwardAndBackInTheMiddle() {
        #expect(OnboardingPaging.target(from: 1, delta: 1, count: 3) == 2)
        #expect(OnboardingPaging.target(from: 1, delta: -1, count: 3) == 0)
    }

    @Test func isNilAtBothEnds() {
        #expect(OnboardingPaging.target(from: 2, delta: 1, count: 3) == nil)
        #expect(OnboardingPaging.target(from: 0, delta: -1, count: 3) == nil)
    }

    @Test func handlesEmptyAndSinglePage() {
        #expect(OnboardingPaging.target(from: 0, delta: 1, count: 0) == nil)
        #expect(OnboardingPaging.target(from: 0, delta: 0, count: 0) == nil)
        #expect(OnboardingPaging.target(from: 0, delta: 1, count: 1) == nil)
        #expect(OnboardingPaging.target(from: 0, delta: -1, count: 1) == nil)
    }

    @Test func isNilWhenCurrentIsOutOfRange() {
        #expect(OnboardingPaging.target(from: -1, delta: 1, count: 3) == nil)
        #expect(OnboardingPaging.target(from: 3, delta: -1, count: 3) == nil)
    }

    @Test func deltaZeroStaysAndLargerDeltasAreNotClamped() {
        #expect(OnboardingPaging.target(from: 1, delta: 0, count: 3) == 1)
        #expect(OnboardingPaging.target(from: 0, delta: 2, count: 3) == 2)
        #expect(OnboardingPaging.target(from: 2, delta: -2, count: 3) == 0)
        #expect(OnboardingPaging.target(from: 1, delta: 2, count: 3) == nil)
        #expect(OnboardingPaging.target(from: 1, delta: -2, count: 3) == nil)
        #expect(OnboardingPaging.target(from: 1, delta: Int.max, count: 3) == nil)
    }
}
