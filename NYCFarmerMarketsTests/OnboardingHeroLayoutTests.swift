import Testing
import CoreGraphics
@testable import NYCFarmerMarkets

struct OnboardingHeroLayoutTests {
    /// Skip size measured on the iPhone 17 simulator at the default text size.
    private let skip = CGSize(width: 55, height: 34)

    private func inset(width: CGFloat, radius: CGFloat, skip: CGSize, safe: CGFloat = 59,
                       heroWidth: CGFloat = 190) -> CGFloat {
        OnboardingHeroLayout.topInset(
            safeAreaTop: safe, containerWidth: width, heroWidth: heroWidth, heroCornerRadius: radius,
            skipSize: skip, skipTopPadding: 8, skipTrailingPadding: 24)
    }

    @Test(arguments: [375.0, 390.0, 393.0, 402.0])
    func circleRisesBesideSkip(width: Double) {
        #expect(inset(width: width, radius: 95, skip: skip) == 67)
    }

    // Framed radius 32: the full half-width (95) applies at Skip's bottom (y = 34 >= 32).
    // 393: 196.5 + 95 + 4 = 295.5 <= 393 - 24 - 55 = 314, rises.
    // 375: 187.5 + 99 = 286.5 <= 296, rises.
    // With the earlier 70 pt estimate, 375 fell back: 286.5 > 281 gives 59 + 8 + 34 + 3 = 104.
    @Test func framedResultsPerWidth() {
        #expect(inset(width: 393, radius: 32, skip: skip) == 67)
        #expect(inset(width: 390, radius: 32, skip: skip) == 67)
        #expect(inset(width: 375, radius: 32, skip: skip) == 67)
        #expect(inset(width: 375, radius: 32, skip: CGSize(width: 70, height: 34)) == 104)
    }

    @Test func largeSkipFallsBackBelowSkip() {
        let large = CGSize(width: 120, height: 50)
        #expect(inset(width: 393, radius: 95, skip: large) == CGFloat(59 + 8 + 50 + 3))
    }

    @Test func equalityBoundaryRises() {
        // Skip left = 393 - 24 - 73.5 = 295.5 equals 196.5 + 95 + 4.
        #expect(inset(width: 393, radius: 32, skip: CGSize(width: 73.5, height: 34)) == 67)
        #expect(inset(width: 393, radius: 32, skip: CGSize(width: 73.75, height: 34)) == 104)
    }

    @Test func negativeAndNonFiniteInputsAreTreatedAsZero() {
        let value = OnboardingHeroLayout.topInset(
            safeAreaTop: -10, containerWidth: CGFloat.nan, heroWidth: CGFloat.infinity, heroCornerRadius: -5,
            skipSize: CGSize(width: -1, height: CGFloat.nan), skipTopPadding: -3, skipTrailingPadding: CGFloat.infinity)
        #expect(value.isFinite)
        #expect(value >= 8)
    }

    @Test(arguments: [320.0, 375.0, 393.0, 430.0])
    func neverBelowSafeAreaPlusMargin(width: Double) {
        for radius in [0.0, 32.0, 95.0] {
            #expect(inset(width: width, radius: radius, skip: skip, safe: 20) >= 28)
        }
    }
}
