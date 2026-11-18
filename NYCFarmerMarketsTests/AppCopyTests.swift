//
//  AppCopyTests.swift
//  NYCFarmerMarketsTests
//
import Testing
@testable import NYCFarmerMarkets

nonisolated struct OnboardingPageCase: Sendable, CustomTestStringConvertible {
    let count: Int
    let index: Int
    var testDescription: String { "page \(index + 1) of \(count)" }
}

struct AppCopyTests {
    @Test func mapFilterSummaryForms() {
        #expect(AppCopy.mapFilterSummary(query: "kale", count: 0) == "No markets lurking for “kale”")
        #expect(AppCopy.mapFilterSummary(query: "kale", count: 1) == "1 market lurking for “kale”")
        #expect(AppCopy.mapFilterSummary(query: "kale", count: 5) == "5 markets lurking for “kale”")
    }

    @Test func queryIsTrimmed() {
        #expect(AppCopy.mapFilterSummary(query: "  kale \n", count: 2) == "2 markets lurking for “kale”")
        #expect(AppCopy.mapFilterAccessibility(query: "  kale ", count: 2) == "Showing 2 results for kale")
    }

    @Test func accessibilityForms() {
        #expect(AppCopy.mapFilterAccessibility(query: "kale", count: 0) == "Showing 0 results for kale")
        #expect(AppCopy.mapFilterAccessibility(query: "kale", count: 1) == "Showing 1 result for kale")
        #expect(AppCopy.mapFilterAccessibility(query: "kale", count: 5) == "Showing 5 results for kale")
    }

    @Test func functionsArePure() {
        let first = AppCopy.mapFilterSummary(query: "a", count: 3)
        let second = AppCopy.mapFilterSummary(query: "a", count: 3)
        #expect(first == second)
        #expect(first == "3 markets lurking for “a”")
        #expect(AppCopy.noResultsHint(query: "zz") == "No markets match “zz”. Try another search.")
    }

    private var allVisibleStrings: [String] {
        [
            AppCopy.splashLoadingCaption, AppCopy.offlineBanner, AppCopy.searchPrompt,
            AppCopy.noResultsTitle, AppCopy.noResultsHint(query: "q"), AppCopy.missingValue,
            AppCopy.mapFilterSummary(query: "q", count: 0), AppCopy.mapFilterSummary(query: "q", count: 1),
            AppCopy.mapFilterSummary(query: "q", count: 2),
            AppCopy.onboardingSkip, AppCopy.onboardingNext, AppCopy.onboardingEnter,
            AppCopy.onboardingPageIndicator(page: 1, count: 3), AppCopy.onboardingPageIndicatorLabel
        ]
    }

    private var plainStrings: [String] {
        [
            AppCopy.splashLoadingAccessibility, AppCopy.offlineBannerAccessibility,
            AppCopy.noResultsTitleAccessibility, AppCopy.missingValueAccessibility,
            AppCopy.mapFilterAccessibility(query: "q", count: 0), AppCopy.mapFilterAccessibility(query: "q", count: 1),
            AppCopy.mapFilterAccessibility(query: "q", count: 2), AppCopy.onboardingPageIndicatorLabel
        ]
    }
    @Test func onboardingPageIndicatorLabelIsPlain() {
        #expect(AppCopy.onboardingPageIndicatorLabel == "Page indicator")
    }

    // Feature: onboarding-flow, Property 7: Button and indicator labels follow the page
    // Validates: Requirements 3.2, 3.3, 3.9, 6.1, 6.8, 7.4
    private static let pageCases: [OnboardingPageCase] = (1...5).flatMap { count in
        (0..<count).map { OnboardingPageCase(count: count, index: $0) }
    }

    @Test(arguments: AppCopyTests.pageCases)
    func onboardingLabelsFollowPage(pageCase: OnboardingPageCase) {
        let isLast = pageCase.index == pageCase.count - 1
        #expect(AppCopy.onboardingPrimaryLabel(isLast: isLast) == (isLast ? "Enter the market" : "Next"))
        #expect(
            AppCopy.onboardingPageIndicator(page: pageCase.index + 1, count: pageCase.count)
                == "Page \(pageCase.index + 1) of \(pageCase.count)"
        )
    }

    @Test func noTechnicalErrorText() {
        for text in allVisibleStrings + plainStrings {
            for banned in ["NSURLErrorDomain", "error -", "Code="] {
                #expect(!text.contains(banned), "\(text)")
            }
        }
    }

    @Test func plainStringsHaveNoSpookyWords() {
        let spooky = ["lurk", "fog", "mist", "haunt", "summon", "spooked"]
        for text in plainStrings {
            #expect(!text.isEmpty)
            for word in spooky {
                #expect(!text.lowercased().contains(word), "\(text)")
            }
        }
    }
}
