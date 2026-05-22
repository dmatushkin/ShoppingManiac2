import Foundation
import Testing
@testable import ShoppingManiac

@MainActor
struct DAOTests {
    @Test("Shopping lists can be created, listed, updated by uniqueId, and soft-deleted")
    func shoppingListLifecycle() async throws {
        let provider = TestContextProvider(container: try makeInMemoryContainer())

        try await withTestContainer(contextProvider: provider) {
            let sut = DAO()
            let old = try await sut.addShoppingList(name: " Old ", date: Date(timeIntervalSince1970: 1), uniqueId: "same")
            let newer = try await sut.addShoppingList(name: "New", date: Date(timeIntervalSince1970: 2), uniqueId: nil)
            let updated = try await sut.addShoppingList(name: "Updated", date: Date(timeIntervalSince1970: 3), uniqueId: "same")
            let lists = try await sut.getShoppingLists()

            #expect(old.uniqueId == updated.uniqueId)
            #expect(updated.name == "Updated")
            #expect(lists.map(\.name) == ["Updated", "New"])

            try await sut.removeShoppingList(newer)
            let remaining = try await sut.getShoppingLists()
            #expect(remaining.map(\.name) == ["Updated"])
        }
    }

    @Test("Shopping list items can be created, edited, toggled, sorted metadata loaded, and soft-deleted")
    func shoppingListItemLifecycle() async throws {
        let provider = TestContextProvider(container: try makeInMemoryContainer())

        try await withTestContainer(contextProvider: provider) {
            let sut = DAO()
            let list = try await sut.addShoppingList(name: "Groceries", date: Date(), uniqueId: "list")
            let store = try await sut.addStore(name: "Market")
            let category = try await sut.addCategory(name: "Dairy")
            try await sut.syncStoreCategories(item: store, categories: [category.name])
            _ = try await sut.addGood(name: "Milk", category: category.name)

            try await sut.addShoppingListItem(
                list: list,
                name: " Milk ",
                amount: "2",
                store: " Market ",
                isWeight: false,
                price: "3",
                isImportant: true,
                rating: 4,
                isPurchased: false,
                uniqueId: "item-1"
            )
            var items = try await sut.getShoppingListItems(list: list)
            var item = try #require(items.first)
            #expect(item.title == "Milk")
            #expect(item.store == "Market")
            #expect(item.category == "Dairy")
            #expect(item.categoryStoreOrder == 0)
            #expect(item.amount == "2")
            #expect(item.price == "3.0")
            #expect(item.isImportant)
            #expect(item.rating == 4)
            #expect(item.isPurchased == false)

            try await sut.editShoppingListItem(item: item, name: "Cheese", amount: "5", store: "", isWeight: true, price: "8", isImportant: false, rating: 2)
            items = try await sut.getShoppingListItems(list: list)
            item = try #require(items.first)
            #expect(item.title == "Cheese")
            #expect(item.store == "")
            #expect(item.amount == "5")
            #expect(item.isWeight)
            #expect(item.isImportant == false)
            #expect(item.rating == 2)

            try await sut.togglePurchasedShoppingListItem(item: item)
            item = try #require(try await sut.getShoppingListItems(list: list).first)
            #expect(item.isPurchased)

            try await sut.removeShoppingListItem(item: item)
            #expect(try await sut.getShoppingListItems(list: list).isEmpty)
        }
    }

    @Test("Goods can be searched, edited, categorized, and removed")
    func goodsLifecycle() async throws {
        let provider = TestContextProvider(container: try makeInMemoryContainer())

        try await withTestContainer(contextProvider: provider) {
            let sut = DAO()
            let good = try await sut.addGood(name: " Milk ", category: " Dairy ")
            _ = try await sut.addGood(name: "Bread", category: "")

            #expect(good.name == "Milk")
            #expect(good.category == "Dairy")
            #expect(try await sut.getGoods(search: "mil").map(\.name) == ["Milk"])

            let edited = try await sut.editGood(item: good, name: "Cheese", category: "")
            #expect(edited.name == "Cheese")
            #expect(edited.category == "")

            try await sut.removeGood(item: edited)
            #expect(try await sut.getGoods(search: "").map(\.name) == ["Bread"])
        }
    }

    @Test("Categories sync normalized unique goods")
    func categoriesLifecycle() async throws {
        let provider = TestContextProvider(container: try makeInMemoryContainer())

        try await withTestContainer(contextProvider: provider) {
            let sut = DAO()
            let category = try await sut.addCategory(name: " Dairy ")
            let edited = try await sut.editCategory(item: category, name: "Fresh Dairy")
            try await sut.syncCategoryGoods(item: edited, goods: ["Milk", " milk ", "", "Cheese"])
            let goods = try await sut.getCategoryGoods(item: edited)

            #expect(edited.name == "Fresh Dairy")
            #expect(goods.map(\.name) == ["Cheese", "Milk"])
            #expect(try await sut.getCategories(search: "fresh").map(\.name) == ["Fresh Dairy"])

            try await sut.removeCategory(item: edited)
            #expect(try await sut.getCategories(search: "").isEmpty)
        }
    }

    @Test("Stores sync normalized unique categories in order")
    func storesLifecycle() async throws {
        let provider = TestContextProvider(container: try makeInMemoryContainer())

        try await withTestContainer(contextProvider: provider) {
            let sut = DAO()
            let store = try await sut.addStore(name: " Market ")
            let edited = try await sut.editStore(item: store, name: "Main Market")
            try await sut.syncStoreCategories(item: edited, categories: ["Dairy", " dairy ", "", "Produce"])
            let categories = try await sut.getStoreCategories(item: edited)

            #expect(edited.name == "Main Market")
            #expect(categories.map(\.name) == ["Dairy", "Produce"])
            #expect(try await sut.getStores(search: "main").map(\.name) == ["Main Market"])

            try await sut.removeStore(item: edited)
            #expect(try await sut.getStores(search: "").isEmpty)
        }
    }

    @Test("DAO throws expected shopping-list errors")
    func shoppingListErrors() async throws {
        let provider = TestContextProvider(container: try makeInMemoryContainer())

        try await withTestContainer(contextProvider: provider) {
            let sut = DAO()
            let missingList = makeList(id: "missing")

            await expectDBError(.unableToGetShoppingList) {
                try await sut.removeShoppingList(missingList)
            }
            await expectDBError(.unableToGetShoppingList) {
                _ = try await sut.getShoppingListItems(list: missingList)
            }
            await expectDBError(.unableToGetShoppingList) {
                try await sut.addShoppingListItem(list: missingList, name: "Milk", amount: "1", store: "", isWeight: false, price: "", isImportant: false, rating: 0, isPurchased: false, uniqueId: nil)
            }
            let list = try await sut.addShoppingList(name: "Groceries", date: Date(), uniqueId: nil)
            await expectDBError(.unableToGetShoppingList) {
                try await sut.addShoppingListItem(list: list, name: "   ", amount: "1", store: "", isWeight: false, price: "", isImportant: false, rating: 0, isPurchased: false, uniqueId: nil)
            }
        }
    }

    @Test("DAO throws expected shopping-list-item errors")
    func shoppingListItemErrors() async throws {
        let provider = TestContextProvider(container: try makeInMemoryContainer())

        try await withTestContainer(contextProvider: provider) {
            let sut = DAO()
            let missingItem = makeShoppingItem(id: "missing")

            await expectDBError(.unableToGetShoppingItem) {
                try await sut.editShoppingListItem(item: missingItem, name: "Milk", amount: "1", store: "", isWeight: false, price: "", isImportant: false, rating: 0)
            }
            await expectDBError(.unableToGetShoppingItem) {
                try await sut.removeShoppingListItem(item: missingItem)
            }
            await expectDBError(.unableToGetShoppingItem) {
                try await sut.togglePurchasedShoppingListItem(item: missingItem)
            }
        }
    }

    @Test("DAO throws expected good errors")
    func goodErrors() async throws {
        let provider = TestContextProvider(container: try makeInMemoryContainer())

        try await withTestContainer(contextProvider: provider) {
            let sut = DAO()
            let missingGood = GoodsItemModel(id: "missing", name: "Missing", category: "")

            await expectDBError(.unableToCreateGood) {
                _ = try await sut.addGood(name: "   ", category: "")
            }
            await expectDBError(.unableToGetGood) {
                _ = try await sut.editGood(item: missingGood, name: "Milk", category: "")
            }
            await expectDBError(.unableToGetGood) {
                try await sut.removeGood(item: missingGood)
            }
        }
    }

    @Test("DAO throws expected category errors")
    func categoryErrors() async throws {
        let provider = TestContextProvider(container: try makeInMemoryContainer())

        try await withTestContainer(contextProvider: provider) {
            let sut = DAO()
            let missingCategory = CategoriesItemModel(id: "missing", name: "Missing")

            await expectDBError(.unableToCreateCategory) {
                _ = try await sut.addCategory(name: "   ")
            }
            await expectDBError(.unableToGetCategory) {
                _ = try await sut.editCategory(item: missingCategory, name: "Dairy")
            }
            await expectDBError(.unableToGetCategory) {
                try await sut.removeCategory(item: missingCategory)
            }
            await expectDBError(.unableToGetCategory) {
                _ = try await sut.getCategoryGoods(item: missingCategory)
            }
            await expectDBError(.unableToGetCategory) {
                try await sut.syncCategoryGoods(item: missingCategory, goods: ["Milk"])
            }
        }
    }

    @Test("DAO throws expected store errors")
    func storeErrors() async throws {
        let provider = TestContextProvider(container: try makeInMemoryContainer())

        try await withTestContainer(contextProvider: provider) {
            let sut = DAO()
            let missingStore = StoresItemModel(id: "missing", name: "Missing")

            await expectDBError(.unableToCreateStore) {
                _ = try await sut.addStore(name: "   ")
            }
            await expectDBError(.unableToGetStore) {
                _ = try await sut.editStore(item: missingStore, name: "Market")
            }
            await expectDBError(.unableToGetStore) {
                try await sut.removeStore(item: missingStore)
            }
            await expectDBError(.unableToGetStore) {
                _ = try await sut.getStoreCategories(item: missingStore)
            }
            await expectDBError(.unableToGetStore) {
                try await sut.syncStoreCategories(item: missingStore, categories: ["Dairy"])
            }
        }
    }
}
