//
//  AppCopyTests.swift
//  NYCFarmerMarketsTests
//
import Testing
@testable import NYCFarmerMarkets

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
        #expect(AppCopy.mapFilterSummary(query: "a", count: 3) == AppCopy.mapFilterSummary(query: "a", count: 3))
        #expect(AppCopy.noResultsHint(query: "zz") == "No markets match “zz”. Try another search.")
    }

    private var allVisibleStrings: [String] {
        [
            AppCopy.splashLoadingCaption, AppCopy.offlineBanner, AppCopy.searchPrompt,
            AppCopy.noResultsTitle, AppCopy.noResultsHint(query: "q"), AppCopy.missingValue,
            AppCopy.mapFilterSummary(query: "q", count: 0), AppCopy.mapFilterSummary(query: "q", count: 1),
            AppCopy.mapFilterSummary(query: "q", count: 2)
        ]
    }

    private var plainStrings: [String] {
        [
            AppCopy.splashLoadingAccessibility, AppCopy.offlineBannerAccessibility,
            AppCopy.noResultsTitleAccessibility, AppCopy.missingValueAccessibility,
            AppCopy.mapFilterAccessibility(query: "q", count: 0), AppCopy.mapFilterAccessibility(query: "q", count: 1),
            AppCopy.mapFilterAccessibility(query: "q", count: 2)
        ]
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
