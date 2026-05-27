//
//  ShoppingManiacUITests.swift
//  ShoppingManiacUITests
//
//  Created by Dmitry Matyushkin on 5/21/26.
//

import XCTest

final class ShoppingManiacUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestInMemoryStore"]
        app.launch()
        return app
    }

    @MainActor
    func testCreatesShoppingListAndItem() throws {
        let app = launchApp()

        createList(named: "Weekend", in: app)
        addItem(named: "Milk", in: app)
    }

    @MainActor
    func testCreatesShoppingList() throws {
        let app = launchApp()

        createList(named: "Weekend", in: app)
    }

    @MainActor
    private func createList(named name: String, in app: XCUIApplication) {
        XCTAssertTrue(app.navigationBars["Shopping lists"].waitForExistence(timeout: 5))
        app.buttons["shopping.addListButton"].tap()

        let listName = app.textFields["Shopping list name"]
        XCTAssertTrue(listName.waitForExistence(timeout: 2))
        listName.tap()
        listName.typeText(name)
        app.buttons["Create"].tap()

        XCTAssertTrue(app.navigationBars[name].waitForExistence(timeout: 5))
    }

    @MainActor
    private func addItem(named name: String, in app: XCUIApplication) {
        app.buttons["shoppingList.addItemButton"].tap()

        let itemName = app.textFields["Item name"]
        XCTAssertTrue(itemName.waitForExistence(timeout: 2))
        itemName.tap()
        itemName.typeText(name)
        app.buttons["Add"].tap()

        XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 5))
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            _ = launchApp()
        }
    }
}
