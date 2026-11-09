import XCTest

final class TempScreenshots: XCTestCase {
    @MainActor
    func testShots() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestingReset"]
        app.launch()
        func save(_ name: String) {
            try? app.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: "/tmp/shot-\(name).png"))
        }
        let row = app.buttons.matching(identifier: "market-row").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 30))
        row.tap()
        XCTAssertTrue(app.buttons["close-detail"].waitForExistence(timeout: 5))
        sleep(1)
        save("detail")
        app.buttons["favorite-toggle"].tap()
        sleep(1)
        save("detail-fav")
        app.buttons["close-detail"].tap()
        app.tabBars.buttons["Map"].tap()
        let pin = app.descendants(matching: .any).matching(identifier: "market-pin").firstMatch
        XCTAssertTrue(pin.waitForExistence(timeout: 15))
        sleep(2)
        save("map")
        pin.tap()
        XCTAssertTrue(app.buttons["more-info"].waitForExistence(timeout: 5))
        sleep(1)
        save("map-selected")
        app.tabBars.buttons["Favorites"].tap()
        sleep(1)
        save("favorites")
    }
}
