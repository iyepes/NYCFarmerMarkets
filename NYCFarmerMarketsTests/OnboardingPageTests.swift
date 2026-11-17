import Testing
import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
@testable import NYCFarmerMarkets

struct OnboardingPageTests {
    private func isBlank(_ text: String) -> Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // Feature: onboarding-flow, Property 8: Page content shape
    // Validates: Requirements 1.4, 5.7, 10.3
    @Test func pageContentShape() {
        let pages = OnboardingPage.all
        #expect(pages.count == 3)
        #expect(Set(pages.map(\.id)).count == pages.count)

        for page in pages {
            #expect(!isBlank(page.eyebrow), "eyebrow of page \(page.id)")
            #expect(!isBlank(page.title), "title of page \(page.id)")
            #expect(!isBlank(page.message), "message of page \(page.id)")
            #expect(page.bullets.count == 3, "bullet count of page \(page.id)")
            for bullet in page.bullets {
                #expect(!isBlank(bullet), "bullet of page \(page.id)")
            }
        }
    }

    // Feature: onboarding-flow, Property 9: Hero images exist
    // Validates: Requirements 7.7, 10.12
    @MainActor
    @Test func heroImagesExist() {
        let bundle = Bundle(for: MarketStore.self)
        let names = OnboardingPage.all.compactMap(\.heroImage)

        for name in names {
            #if canImport(UIKit)
            #expect(UIImage(named: name, in: bundle, with: nil) != nil, "missing image \(name)")
            #elseif canImport(AppKit)
            #expect(bundle.image(forResource: NSImage.Name(name)) != nil, "missing image \(name)")
            #endif
        }

        let expected = ["pirate-ship", "map-image", "dairy-products-pallete"]
        #expect(names.count == expected.count)
        #expect(Set(names) == Set(expected))
        for name in expected {
            #expect(names.filter { $0 == name }.count == 1, "\(name) used once")
        }
    }
}
