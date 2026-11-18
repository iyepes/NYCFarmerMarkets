//
//  OnboardingUITests.swift
//  NYCFarmerMarketsUITests
//
//  These tests use the live NYC Open Data API (or the on-device cache).
//

import XCTest

final class OnboardingUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    // MARK: Helpers

    private func launchWithOnboarding() {
        app.launchArguments = ["-uiTestingReset", "-uiTestingResetOnboarding", "-uiTestingMuteSounds"]
        app.launch()
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier].firstMatch
    }

    private var onboardingScreen: XCUIElement { element("onboarding-screen") }
    private var nextButton: XCUIElement { element("onboarding-next") }
    private var skipButton: XCUIElement { element("onboarding-skip") }
    private var pageIndicator: XCUIElement { element("onboarding-page-indicator") }

    private func tabItem(_ name: String) -> XCUIElement {
        let tab = app.tabBars.buttons[name]
        return tab.exists ? tab : app.buttons[name].firstMatch
    }

    private var tabNames: [String] { ["Markets", "Map", "Favorites"] }

    private func assertTabsAppear(file: StaticString = #filePath, line: UInt = #line) {
        for name in tabNames {
            XCTAssertTrue(tabItem(name).waitForExistence(timeout: 30), "\(name) tab did not appear", file: file, line: line)
        }
    }

    // MARK: Tests

    @MainActor
    func testOnboardingShowsAfterSplashWithoutTabs() throws {
        launchWithOnboarding()
        XCTAssertTrue(onboardingScreen.waitForExistence(timeout: 30), "Onboarding did not appear")
        for name in tabNames {
            XCTAssertFalse(app.tabBars.buttons[name].exists, "\(name) tab should not exist during onboarding")
            XCTAssertFalse(app.buttons[name].exists, "\(name) tab should not exist during onboarding")
        }
    }

    @MainActor
    func testNextTwiceThenEnterTheMarket() throws {
        launchWithOnboarding()
        XCTAssertTrue(nextButton.waitForExistence(timeout: 30), "Next did not appear")
        nextButton.tap()
        nextButton.tap()

        // The page change is animated, so wait for the last-page state.
        let lastPage = NSPredicate(format: "label == %@", "Enter the market")
        expectation(for: lastPage, evaluatedWith: nextButton)
        waitForExpectations(timeout: 5)
        XCTAssertEqual(nextButton.label, "Enter the market")
        // Skip is hidden with opacity 0 and disabled on the last page. XCUITest ignores opacity
        // for `isHittable`, so the disabled state is what shows that it cannot be used.
        XCTAssertTrue(!skipButton.exists || !skipButton.isEnabled || !skipButton.isHittable,
                      "Skip should not be usable on the last page")

        nextButton.tap()
        assertTabsAppear()
        XCTAssertFalse(onboardingScreen.exists)
    }

    @MainActor
    func testSkipLeavesOnboarding() throws {
        launchWithOnboarding()
        XCTAssertTrue(skipButton.waitForExistence(timeout: 30), "Skip did not appear")
        skipButton.tap()

        assertTabsAppear()
        XCTAssertFalse(onboardingScreen.exists)
    }

    @MainActor
    func testOnboardingShowsOnlyOnce() throws {
        launchWithOnboarding()
        XCTAssertTrue(skipButton.waitForExistence(timeout: 30), "Skip did not appear")
        skipButton.tap()
        assertTabsAppear()

        app.terminate()
        app.launchArguments = ["-uiTestingMuteSounds"]
        app.launch()

        // Poll until the tabs show; onboarding must never appear in that window.
        let deadline = Date().addingTimeInterval(30)
        var tabsShown = false
        while Date() < deadline {
            XCTAssertFalse(onboardingScreen.exists, "Onboarding appeared again")
            if tabItem("Markets").exists { tabsShown = true; break }
            Thread.sleep(forTimeInterval: 0.25)
        }
        XCTAssertTrue(tabsShown, "Tabs did not appear after relaunch")
        XCTAssertFalse(onboardingScreen.exists, "Onboarding appeared again")
    }

    @MainActor
    func testSwipeMovesToSecondPage() throws {
        launchWithOnboarding()
        XCTAssertTrue(onboardingScreen.waitForExistence(timeout: 30), "Onboarding did not appear")
        XCTAssertTrue(pageIndicator.waitForExistence(timeout: 5))
        XCTAssertEqual(indicatorValue, "Page 1 of 3")

        onboardingScreen.swipeLeft()

        waitForIndicator("Page 2 of 3")
        XCTAssertEqual(indicatorValue, "Page 2 of 3")
    }

    @MainActor
    func testNextTapsOutsideTextAdvance() throws {
        launchWithOnboarding()
        XCTAssertTrue(nextButton.waitForExistence(timeout: 30), "Next did not appear")
        XCTAssertTrue(pageIndicator.waitForExistence(timeout: 5))
        XCTAssertEqual(indicatorValue, "Page 1 of 3")

        // Inside the capsule, far left of the centered text.
        nextButton.coordinate(withNormalizedOffset: CGVector(dx: 0.04, dy: 0.5)).tap()

        waitForIndicator("Page 2 of 3")
    }

    @MainActor
    func testPageIndicatorFrameIsAtLeast44Points() throws {
        launchWithOnboarding()
        XCTAssertTrue(pageIndicator.waitForExistence(timeout: 30), "Indicator did not appear")
        let frame = pageIndicator.frame
        XCTAssertGreaterThanOrEqual(frame.height, 44, "Indicator height \(frame.height)")
        XCTAssertGreaterThanOrEqual(frame.width, 44, "Indicator width \(frame.width)")
    }

    // No UI test for the indicator's adjust actions: XCUITest's adjust(toNormalizedSliderPosition:)
    // only works on sliders. OnboardingPagingTests and the owner's VoiceOver check cover it (AC 6.2).

    @MainActor
    func testOnboardingScreenshotsAtDefaultAndLargestText() throws {
        for size in [nil, "UICTContentSizeCategoryAccessibilityXXXL"] {
            var arguments = ["-uiTestingReset", "-uiTestingResetOnboarding", "-uiTestingMuteSounds"]
            if let size { arguments += ["-UIPreferredContentSizeCategoryName", size] }
            app.launchArguments = arguments
            app.launch()
            let tag = size == nil ? "default" : "ax-xxxl"
            XCTAssertTrue(nextButton.waitForExistence(timeout: 30), "Next did not appear (\(tag))")
            attachScreenshot("onboarding-page0-\(tag) skip=\(skipButton.frame) next=\(nextButton.frame)")

            nextButton.tap()
            nextButton.tap()
            waitForIndicator("Page 3 of 3")
            XCTAssertTrue(nextButton.isHittable, "Next not hittable on the last page (\(tag))")
            XCTAssertTrue(pageIndicator.isHittable, "Indicator not hittable on the last page (\(tag))")
            attachScreenshot("onboarding-page2-\(tag) next=\(nextButton.frame)")
            app.terminate()
        }
    }

    // MARK: Indicator helpers

    private var indicatorValue: String? { pageIndicator.value as? String }

    private func waitForIndicator(_ value: String, file: StaticString = #filePath, line: UInt = #line) {
        let predicate = NSPredicate(format: "value == %@", value)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: pageIndicator)
        let result = XCTWaiter().wait(for: [expectation], timeout: 5)
        XCTAssertEqual(result, .completed, "Indicator value is \(indicatorValue ?? "nil"), expected \(value)",
                       file: file, line: line)
    }

    private func attachScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
