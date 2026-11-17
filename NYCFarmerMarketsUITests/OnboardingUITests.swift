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
        XCTAssertEqual(pageIndicator.label, "Page 1 of 3")

        onboardingScreen.swipeLeft()

        let moved = NSPredicate(format: "label == %@", "Page 2 of 3")
        expectation(for: moved, evaluatedWith: pageIndicator)
        waitForExpectations(timeout: 5)
        XCTAssertEqual(pageIndicator.label, "Page 2 of 3")
    }
}
