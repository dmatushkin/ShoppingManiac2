import Testing
@testable import ShoppingManiac

@MainActor
struct ShoppingListSorterTests {
    @Test("Empty shopping list produces no sections or loose items")
    func emptyInput() {
        let output = ShoppingListSorter().sort([])

        #expect(output.sections.isEmpty)
        #expect(output.items.isEmpty)
    }

    @Test("Items without stores or categories are sorted by purchase state then title")
    func noStoreItemsAreSortedByPurchaseStateThenTitle() {
        let output = ShoppingListSorter().sort([
            makeShoppingItem(title: "Zucchini", isPurchased: false),
            makeShoppingItem(title: "Apples", isPurchased: true),
            makeShoppingItem(title: "Bread", isPurchased: false)
        ])

        #expect(output.sections.isEmpty)
        #expect(output.items.map(\.title) == ["Bread", "Zucchini", "Apples"])
    }

    @Test("Store and category sections are sorted predictably")
    func storeAndCategorySections() throws {
        let output = ShoppingListSorter().sort([
            makeShoppingItem(title: "Carrots", store: "Market", category: "Vegetables", categoryStoreOrder: 1),
            makeShoppingItem(title: "Cheese", store: "Market", category: "Dairy", categoryStoreOrder: 0),
            makeShoppingItem(title: "Yogurt", store: "Market", category: "Dairy", categoryStoreOrder: 0, isPurchased: true),
            makeShoppingItem(title: "Rice", store: "Corner", category: "Pantry", categoryStoreOrder: nil),
            makeShoppingItem(title: "Bananas", store: "", category: "Fruit", categoryStoreOrder: nil),
            makeShoppingItem(title: "Soap", store: "", category: "", categoryStoreOrder: nil)
        ])

        #expect(output.sections.map(\.title) == ["Corner", "Market", "Fruit"])
        let corner = try #require(output.sections.first { $0.title == "Corner" })
        let market = try #require(output.sections.first { $0.title == "Market" })
        let looseFruit = try #require(output.sections.first { $0.title == "Fruit" })

        #expect(corner.subsections.map(\.title) == ["Pantry"])
        #expect(corner.subsections.first?.items.map(\.title) == ["Rice"])
        #expect(market.subsections.map(\.title) == ["Dairy", "Vegetables"])
        #expect(market.subsections.first?.items.map(\.title) == ["Cheese", "Yogurt"])
        #expect(looseFruit.items.map(\.title) == ["Bananas"])
        #expect(output.items.map(\.title) == ["Soap"])
    }
}
