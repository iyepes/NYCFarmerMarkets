import XCTest

/// Launches the app with a store that has no cache and a download that always
/// fails, so the splash must remain visible with an error and a Retry button.
final class SplashFailureUITests: XCTestCase {

    private var app: XCUIApplication!

    @MainActor
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTestingReset", "-uiTestingMuteSounds", "-uiTestingFailDownload"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    @MainActor
    func testRetryAndErrorShownWhenDownloadFailsWithoutCache() throws {
        let splash = element("splash-screen")
        let error = element("splash-error")
        let retry = app.buttons["splash-retry"]

        XCTAssertTrue(splash.waitForExistence(timeout: 10),
                      "Splash screen should be shown when the download fails and no cache exists")
        XCTAssertTrue(error.waitForExistence(timeout: 10),
                      "Splash error message should be shown when the download fails")
        XCTAssertTrue(retry.waitForExistence(timeout: 10),
                      "Retry button should be shown when the download fails")
        XCTAssertEqual(error.label, "You're off the grid", "Offline failure should show the friendly title")
        let hint = element("splash-error-hint")
        XCTAssertTrue(hint.waitForExistence(timeout: 5), "A plain-language hint should be shown")
        XCTAssertEqual(hint.label, "Check your connection, then try again.")
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'NSURLErrorDomain'")).firstMatch.exists,
                       "Technical error text must not be shown")
        XCTAssertEqual(retry.label, "Retry loading markets",
                       "Retry button should have the accessibility label 'Retry loading markets'")

        XCTAssertFalse(app.tabBars.firstMatch.exists,
                       "Tab bar must not be shown while the splash is displaying an error")
        let sectionHeaders = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "section-header-"))
        XCTAssertEqual(sectionHeaders.count, 0,
                       "No borough section headers should exist while the splash is displayed")

        retry.tap()

        XCTAssertTrue(splash.waitForExistence(timeout: 10),
                      "Splash screen should remain after a failed retry")
        XCTAssertTrue(error.waitForExistence(timeout: 10),
                      "Error message should return after the retry fails")
        XCTAssertTrue(retry.waitForExistence(timeout: 10),
                      "Retry button should return after the retry fails")
        XCTAssertFalse(app.tabBars.firstMatch.exists,
                       "Tab bar must still not be shown after a failed retry")
    }
}
