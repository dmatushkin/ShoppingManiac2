//
//  ShoppingManiacUITests.swift
//  ShoppingManiacUITests
//
//  Created by Dmitry Matyushkin on 5/21/26.
//

import XCTest

final class ShoppingManiacUITests: XCTestCase {

    private enum Tab {
        static let shopping = "Shopping"
        static let goods = "Goods"
        static let stores = "Stores"
        static let categories = "Categories"
        static let about = "About"
    }

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
    func testShoppingScreenCoversListItemEditDeleteAndShareMenu() throws {
        let app = launchApp()

        createList(named: "Weekend", in: app)
        addShoppingItem(named: "Milk",
                        store: "Market",
                        amount: "2",
                        price: "3.50",
                        isImportant: true,
                        rating: 3,
                        in: app)

        XCTAssertTrue(app.staticTexts["Market"].waitForExistence(timeout: 5))
        
        enterText("milk", into: "Search", in: app)
        XCTAssertTrue(app.staticTexts["Milk"].waitForExistence(timeout: 5))
        enterText("", into: "Search", in: app, replacingExistingText: true)
        dismissSearch(in: app)

        app.staticTexts["Milk"].tap()
        editVisibleRow(named: "Milk", in: app)
        enterText("Bread", into: "Item name", in: app, replacingExistingText: true)
        app.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["Bread"].waitForExistence(timeout: 5))

        app.buttons["shoppingList.shareButton"].tap()
        XCTAssertTrue(app.buttons["Share with file"].waitForExistence(timeout: 2))
        dismissPresentedMenu(in: app)

        deleteVisibleRow(named: "Bread", in: app)
    }

    @MainActor
    func testGoodsScreenCoversAddSearchEditAndDelete() throws {
        let app = launchApp()

        openTab(Tab.goods, in: app)
        waitForNavigationBar("Goods", in: app)

        app.buttons["goods.addButton"].tap()
        enterText("Apples", into: "Good name", in: app)
        enterText("Fruit", into: "Category name", in: app)
        app.buttons["goodEditor.saveButton"].tap()
        XCTAssertTrue(app.staticTexts["Apples"].waitForExistence(timeout: 5))

        enterText("app", into: "Search", in: app)
        XCTAssertTrue(app.staticTexts["Apples"].waitForExistence(timeout: 5))

        enterText("", into: "Search", in: app, replacingExistingText: true)
        tapVisibleRow(named: "Apples", in: app)
        waitForNavigationBar("Edit good", in: app)
        enterText("Green apples", into: "Good name", in: app, replacingExistingText: true)
        enterText("Produce", into: "Category name", in: app, replacingExistingText: true)
        app.buttons["goodEditor.saveButton"].tap()
        waitForNavigationBar("Goods", in: app)
        XCTAssertTrue(app.staticTexts["Green apples"].waitForExistence(timeout: 5))

        deleteVisibleRow(named: "Green apples", in: app)
    }

    @MainActor
    func testCategoriesScreenCoversAddGoodsSearchEditAndDelete() throws {
        let app = launchApp()

        openTab(Tab.categories, in: app)
        waitForNavigationBar("Categories", in: app)

        app.buttons["categories.addButton"].tap()
        enterText("Breakfast", into: "Category name", in: app)
        addGood("Oats", toCategoryIn: app)
        XCTAssertTrue(app.staticTexts["Oats"].waitForExistence(timeout: 5))
        app.buttons["categoryEditor.saveButton"].tap()
        XCTAssertTrue(app.staticTexts["Breakfast"].waitForExistence(timeout: 5))

        enterText("break", into: "Search", in: app)
        XCTAssertTrue(app.staticTexts["Breakfast"].waitForExistence(timeout: 5))

        enterText("", into: "Search", in: app, replacingExistingText: true)
        tapVisibleRow(named: "Breakfast", in: app)
        waitForNavigationBar("Edit category", in: app)
        XCTAssertTrue(app.staticTexts["Oats"].waitForExistence(timeout: 5))
        addGood("Milk", toCategoryIn: app)
        XCTAssertTrue(app.staticTexts["Milk"].waitForExistence(timeout: 5))
        enterText("Morning food", into: "Category name", in: app, replacingExistingText: true)
        app.buttons["categoryEditor.saveButton"].tap()
        waitForNavigationBar("Categories", in: app)
        XCTAssertTrue(app.staticTexts["Morning food"].waitForExistence(timeout: 5))

        deleteVisibleRow(named: "Morning food", in: app)
    }

    @MainActor
    func testStoresScreenCoversAddCategoriesSearchEditAndDelete() throws {
        let app = launchApp()

        openTab(Tab.stores, in: app)
        waitForNavigationBar("Stores", in: app)

        app.buttons["stores.addButton"].tap()
        enterText("Corner Market", into: "Store name", in: app)
        addCategory("Dairy", toStoreIn: app)
        XCTAssertTrue(app.staticTexts["Dairy"].waitForExistence(timeout: 5))
        app.buttons["storeEditor.saveButton"].tap()
        XCTAssertTrue(app.staticTexts["Corner Market"].waitForExistence(timeout: 5))

        enterText("corner", into: "Search", in: app)
        XCTAssertTrue(app.staticTexts["Corner Market"].waitForExistence(timeout: 5))

        enterText("", into: "Search", in: app, replacingExistingText: true)
        tapVisibleRow(named: "Corner Market", in: app)
        waitForNavigationBar("Edit store", in: app)
        XCTAssertTrue(app.staticTexts["Dairy"].waitForExistence(timeout: 5))
        addCategory("Bakery", toStoreIn: app)
        XCTAssertTrue(app.staticTexts["Bakery"].waitForExistence(timeout: 5))
        enterText("City Market", into: "Store name", in: app, replacingExistingText: true)
        app.buttons["storeEditor.saveButton"].tap()
        waitForNavigationBar("Stores", in: app)
        XCTAssertTrue(app.staticTexts["City Market"].waitForExistence(timeout: 5))

        deleteVisibleRow(named: "City Market", in: app)
    }

    @MainActor
    func testAboutScreenCoversStaticContentAndBackupEmptyState() throws {
        let app = launchApp()

        openTab(Tab.about, in: app)
        XCTAssertTrue(app.staticTexts["Simple application to organize your shopping lists"].waitForExistence(timeout: 5))

        app.buttons["about.createBackupButton"].tap()
        XCTAssertTrue(app.staticTexts["Nothing to back up"].waitForExistence(timeout: 5))
    }

    @MainActor
    private func createList(named name: String, in app: XCUIApplication) {
        XCTAssertTrue(app.navigationBars["Shopping lists"].waitForExistence(timeout: 5))
        app.buttons["shopping.addListButton"].tap()

        enterText(name, into: "Shopping list name", in: app)
        app.buttons["Create"].tap()

        XCTAssertTrue(app.navigationBars[name].waitForExistence(timeout: 5))
    }

    @MainActor
    private func addShoppingItem(named name: String,
                                 store: String,
                                 amount: String,
                                 price: String,
                                 isImportant: Bool,
                                 rating: Int,
                                 in app: XCUIApplication) {
        app.buttons["shoppingList.addItemButton"].tap()

        enterText(name, into: "Item name", in: app)
        enterText(store, into: "Store name", in: app)
        enterText(amount, into: "Amount", in: app, replacingExistingText: true)
        enterText(price, into: "Price", in: app, replacingExistingText: true)
        if isImportant {
            app.switches["Is important"].tap()
        }
        app.buttons["rating.star.\(rating)"].tap()
        app.buttons["Add"].tap()

        XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 5))
    }

    @MainActor
    private func addGood(_ name: String, toCategoryIn app: XCUIApplication) {
        app.buttons["categoryEditor.addGoodButton"].tap()
        enterText(name, into: "Good name", in: app)
        app.buttons["addGoodToCategory.saveButton"].tap()
    }

    @MainActor
    private func addCategory(_ name: String, toStoreIn app: XCUIApplication) {
        app.buttons["storeEditor.addCategoryButton"].tap()
        enterText(name, into: "Category name", in: app)
        app.buttons["addCategoryToStore.saveButton"].tap()
    }

    @MainActor
    private func openTab(_ title: String, in app: XCUIApplication) {
        let tab = app.tabBars.buttons[title]
        XCTAssertTrue(tab.waitForExistence(timeout: 5), "Missing tab \(title)")
        tab.tap()
    }

    @MainActor
    private func waitForNavigationBar(_ title: String, in app: XCUIApplication) {
        XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 5), "Missing navigation title \(title)")
    }

    @MainActor
    private func enterText(_ text: String,
                           into fieldIdentifier: String,
                           in app: XCUIApplication,
                           replacingExistingText: Bool = false) {
        let textField = app.textFields[fieldIdentifier]
        let field: XCUIElement
        if textField.waitForExistence(timeout: 2) {
            field = textField
        } else {
            field = app.searchFields[fieldIdentifier]
        }
        XCTAssertTrue(field.waitForExistence(timeout: 5), "Missing text field \(fieldIdentifier)")
        if replacingExistingText {
            field.clearAndTypeText(text)
        } else {
            field.tap()
            field.typeText(text)
        }
    }

    @MainActor
    private func tapVisibleRow(named name: String, in app: XCUIApplication) {
        let rowText = app.staticTexts[name]
        XCTAssertTrue(rowText.waitForExistence(timeout: 5), "Missing row \(name)")
        rowText.tap()
    }

    @MainActor
    private func editVisibleRow(named name: String, in app: XCUIApplication) {
        revealSwipeActions(forRowNamed: name, in: app)
        let editButton = app.buttons["Edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 2), "Missing Edit action for \(name)")
        editButton.tap()
    }

    @MainActor
    private func deleteVisibleRow(named name: String, in app: XCUIApplication) {
        revealSwipeActions(forRowNamed: name, in: app)
        let deleteButton = app.buttons["Delete"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 2), "Missing Delete action for \(name)")
        deleteButton.tap()
        waitForElementToDisappear(app.staticTexts[name])
    }

    @MainActor
    private func revealSwipeActions(forRowNamed name: String, in app: XCUIApplication) {
        let row = app.cells.containing(.staticText, identifier: name).firstMatch
        if row.waitForExistence(timeout: 2) {
            row.swipeLeft()
        } else {
            let rowText = app.staticTexts[name]
            XCTAssertTrue(rowText.waitForExistence(timeout: 5), "Missing row \(name)")
            rowText.swipeLeft()
        }
    }

    @MainActor
    private func dismissPresentedMenu(in app: XCUIApplication) {
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.waitForExistence(timeout: 1) {
            cancelButton.tap()
        } else {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap()
        }
    }
    
    @MainActor
    private func dismissSearch(in app: XCUIApplication) {
        let closeButton = app.buttons["Close"]
        if closeButton.waitForExistence(timeout: 1) {
            closeButton.tap()
        }
    }

    @MainActor
    private func waitForElementToDisappear(_ element: XCUIElement) {
        let predicate = NSPredicate(format: "exists == false")
        expectation(for: predicate, evaluatedWith: element)
        waitForExpectations(timeout: 5)
    }
}

private extension XCUIElement {
    @MainActor
    func clearAndTypeText(_ text: String) {
        tap()

        let currentValue = value as? String ?? ""
        let placeholder = placeholderValue ?? ""
        if !currentValue.isEmpty && currentValue != placeholder {
            typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count))
        }

        if !text.isEmpty {
            typeText(text)
        }
    }
}
