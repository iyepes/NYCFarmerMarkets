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

    private func waitForMarkets(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(firstMarketRow.waitForExistence(timeout: 30), "Markets did not load", file: file, line: line)
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

    @MainActor
    func testSearchFiltersList() throws {
        waitForMarkets()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("zzzzzz")
        XCTAssertTrue(app.staticTexts["No markets found"].waitForExistence(timeout: 5))
    }
}
