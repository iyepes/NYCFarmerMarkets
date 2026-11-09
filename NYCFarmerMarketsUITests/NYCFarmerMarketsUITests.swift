//
//  NYCFarmerMarketsUITests.swift
//  NYCFarmerMarketsUITests
//
//  Created by Isabel Yepes on 8/11/26.
//
//  These tests use the live NYC Open Data API (or the on-device cache).
//

import XCTest

final class NYCFarmerMarketsUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTestingReset"]
        app.launch()
    }

    // MARK: Helpers

    private var firstMarketRow: XCUIElement { app.buttons.matching(identifier: "market-row").firstMatch }

    private var firstSectionHeader: XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'section-header-'"))
            .firstMatch
    }

    /// Waits for the splash to dismiss and sections to load, expands the first section if needed,
    /// then waits for a market row.
    private func waitForMarkets(file: StaticString = #filePath, line: UInt = #line) {
        let header = firstSectionHeader
        XCTAssertTrue(header.waitForExistence(timeout: 30), "Markets did not load", file: file, line: line)
        if !firstMarketRow.exists { header.tap() }
        XCTAssertTrue(firstMarketRow.waitForExistence(timeout: 5), "Section did not expand", file: file, line: line)
    }

    private func waitForSectionHeader(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(firstSectionHeader.waitForExistence(timeout: 30), "Markets did not load", file: file, line: line)
    }

    private func selectTab(_ name: String) {
        let tab = app.tabBars.buttons[name]
        if tab.exists { tab.tap() } else { app.buttons[name].firstMatch.tap() }
    }

    private var closeButton: XCUIElement { app.buttons["close-detail"] }

    // MARK: Tests

    /// List -> detail sheet -> Close -> back on the list.
    @MainActor
    func testOpenDetailFromListAndClose() throws {
        waitForMarkets()
        firstMarketRow.tap()

        XCTAssertTrue(closeButton.waitForExistence(timeout: 5), "Detail sheet did not open")
        XCTAssertTrue(app.buttons["favorite-toggle"].exists)

        closeButton.tap()
        XCTAssertTrue(firstMarketRow.waitForExistence(timeout: 5), "Did not return to the list")
        XCTAssertFalse(closeButton.exists)
    }

    /// Favorite in the sheet -> shows in Favorites tab -> swipe to remove -> empty state.
    @MainActor
    func testFavoriteAppearsInFavoritesTabAndSwipeRemoves() throws {
        waitForMarkets()

        selectTab("Favorites")
        XCTAssertTrue(app.descendants(matching: .any)["favorites-empty"].waitForExistence(timeout: 5))

        selectTab("Markets")
        waitForMarkets()
        firstMarketRow.tap()
        XCTAssertTrue(closeButton.waitForExistence(timeout: 5))
        app.buttons["favorite-toggle"].tap()
        closeButton.tap()

        selectTab("Favorites")
        let row = app.buttons.matching(identifier: "favorite-row").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5), "Favorite did not appear")

        // Tapping shows details; closing returns to Favorites.
        row.tap()
        XCTAssertTrue(closeButton.waitForExistence(timeout: 5))
        closeButton.tap()
        XCTAssertTrue(row.waitForExistence(timeout: 5))

        row.swipeLeft()
        let remove = app.buttons["Remove"].firstMatch
        XCTAssertTrue(remove.waitForExistence(timeout: 5), "Swipe action did not appear")
        remove.tap()

        XCTAssertTrue(app.descendants(matching: .any)["favorites-empty"].waitForExistence(timeout: 5))
    }

    /// Map -> select a pin -> card -> More info -> Close -> back on the map.
    @MainActor
    func testMapPinMoreInfoAndClose() throws {
        waitForMarkets()
        selectTab("Map")

        let map = app.maps.firstMatch
        XCTAssertTrue(map.waitForExistence(timeout: 10))

        let pin = app.descendants(matching: .any).matching(identifier: "market-pin").firstMatch
        XCTAssertTrue(pin.waitForExistence(timeout: 15), "No pins on the map")
        pin.tap()

        let moreInfo = app.buttons["more-info"]
        XCTAssertTrue(moreInfo.waitForExistence(timeout: 5), "Card did not appear after selecting a pin")
        moreInfo.tap()

        XCTAssertTrue(closeButton.waitForExistence(timeout: 5), "Detail sheet did not open")
        closeButton.tap()

        XCTAssertTrue(app.buttons["more-info"].waitForExistence(timeout: 5), "Did not return to the map")
    }

    /// Opens the detail sheet from a map pin and returns once its buttons are visible.
    private func openDetailFromMapPin() {
        waitForMarkets()
        selectTab("Map")
        let pin = element("market-pin")
        XCTAssertTrue(pin.waitForExistence(timeout: 15), "No pins on the map")
        pin.tap()
        let moreInfo = app.buttons["more-info"]
        XCTAssertTrue(moreInfo.waitForExistence(timeout: 5), "Card did not appear after selecting a pin")
        moreInfo.tap()
        XCTAssertTrue(closeButton.waitForExistence(timeout: 5), "Detail sheet did not open")
    }

    /// Taps "Open in Maps" and waits for the pushed single-market map.
    private func pushSingleMarketMap() {
        let openInMaps = app.buttons["open-in-maps"]
        XCTAssertTrue(openInMaps.waitForExistence(timeout: 5), "Open in Maps button missing")
        openInMaps.tap()
        XCTAssertTrue(element("market-location-map").waitForExistence(timeout: 10), "Single-market map did not appear")
    }

    /// Detail -> Open in Maps pushes the in-app map with one pin -> Back returns to the same detail.
    @MainActor
    func testOpenInMapsPushesSingleMarketMap() throws {
        openDetailFromMapPin()
        XCTAssertTrue(app.buttons["open-in-maps"].exists)
        XCTAssertTrue(app.buttons["look-for-directions"].exists, "Directions button missing")

        pushSingleMarketMap()
        XCTAssertEqual(
            app.descendants(matching: .any).matching(identifier: "selected-market-pin").count, 1,
            "The pushed map should show exactly one pin"
        )
        waitUntilGone(app.buttons["open-in-maps"], "Detail content should be covered by the pushed map")
        XCTAssertTrue(closeButton.exists, "Close should stay available on the pushed map")
        XCTAssertTrue(app.buttons["favorite-toggle"].exists, "Favorite toggle should stay available on the pushed map")

        let back = [app.navigationBars.buttons["Market details"], app.buttons["Market details"], app.buttons["Back"]]
            .first { $0.exists }
        XCTAssertNotNil(back, "No Back button on the pushed map")
        back?.tap()
        XCTAssertTrue(app.buttons["open-in-maps"].waitForExistence(timeout: 5), "Did not return to the detail screen")
        XCTAssertTrue(app.buttons["look-for-directions"].exists)
    }

    /// Close on the pushed map dismisses the whole detail sheet.
    @MainActor
    func testCloseFromPushedMapDismissesSheet() throws {
        openDetailFromMapPin()
        pushSingleMarketMap()

        closeButton.tap()
        XCTAssertTrue(app.buttons["more-info"].waitForExistence(timeout: 5), "Did not return to the map tab")
        waitUntilGone(closeButton, "Detail sheet should be dismissed")
    }

    // MARK: Splash and collapsible sections

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    private func waitUntilGone(_ element: XCUIElement, timeout: TimeInterval = 10, _ message: String,
                               file: StaticString = #filePath, line: UInt = #line) {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: element)
        XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: timeout), .completed, message, file: file, line: line)
    }

    private func waitForValue(_ value: String, of element: XCUIElement, timeout: TimeInterval = 5,
                              file: StaticString = #filePath, line: UInt = #line) {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", value), object: element)
        XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: timeout), .completed,
                       "Expected value \(value) but was \(String(describing: element.value))", file: file, line: line)
    }

    @MainActor
    func testSplashAppearsAtLaunch() throws {
        // launch() returns only once the app is idle (~3 s), which is after the default 1 s splash,
        // so relaunch with a longer minimum display time to observe the splash.
        app.terminate()
        app.launchArguments = ["-uiTestingReset", "-uiTestingSplashMinimumSeconds", "6"]
        app.launch()
        XCTAssertTrue(element("splash-screen").waitForExistence(timeout: 2), "Splash did not appear at launch")
        XCTAssertTrue(element("splash-loading").exists, "Splash should show the loading indicator")
        XCTAssertFalse(app.tabBars.firstMatch.exists, "Tabs should not show while the splash is visible")

        waitForSectionHeader()
        waitUntilGone(element("splash-screen"), "Splash did not dismiss after markets loaded")
    }

    @MainActor
    func testSectionsStartCollapsed() throws {
        waitForSectionHeader()
        XCTAssertFalse(firstMarketRow.exists, "No market rows should be visible at launch")
        for borough in ["Manhattan", "Brooklyn", "Queens"] {
            let header = element("section-header-\(borough)")
            XCTAssertTrue(header.waitForExistence(timeout: 5), "Missing header for \(borough)")
            XCTAssertEqual(header.value as? String, "Collapsed", "\(borough) should start collapsed")
        }
    }

    @MainActor
    func testTappingHeaderExpandsAndCollapses() throws {
        waitForSectionHeader()
        let header = element("section-header-Manhattan")
        XCTAssertTrue(header.waitForExistence(timeout: 5))

        header.tap()
        waitForValue("Expanded", of: header)
        XCTAssertTrue(firstMarketRow.waitForExistence(timeout: 5), "Expanding should show market rows")

        header.tap()
        waitForValue("Collapsed", of: header)
        waitUntilGone(firstMarketRow, "Collapsing should hide market rows")
    }

    @MainActor
    func testSearchAutoExpandsMatchingBoroughs() throws {
        waitForSectionHeader()
        let header = element("section-header-Manhattan")
        XCTAssertTrue(header.waitForExistence(timeout: 5))
        XCTAssertEqual(header.value as? String, "Collapsed")

        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("Manhattan")

        waitForValue("Expanded", of: header)
        XCTAssertTrue(firstMarketRow.waitForExistence(timeout: 5), "Matching section should show rows")

        header.tap()
        waitForValue("Collapsed", of: header)

        let clear = search.buttons["Clear text"]
        if clear.exists {
            clear.tap()
        } else {
            search.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: "Manhattan".count))
        }
        XCTAssertTrue(header.waitForExistence(timeout: 5))
        waitForValue("Collapsed", of: header)
    }

    @MainActor
    func testSearchFiltersList() throws {
        waitForSectionHeader()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("zzzzzz")
        XCTAssertTrue(app.staticTexts["No markets found"].waitForExistence(timeout: 5))
    }
}
