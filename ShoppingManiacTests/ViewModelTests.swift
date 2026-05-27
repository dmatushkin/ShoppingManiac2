import Foundation
import Testing
@testable import ShoppingManiac

@MainActor
struct ViewModelTests {
    @Test("ShoppingModel loads, reloads from app events, adds, cancels, and deletes lists")
    func shoppingModelSuccessPaths() async throws {
        let dao = StubDAO()
        let events = SpyAppEventCenter()
        dao.shoppingLists = [makeList(id: "1", name: "First")]

        try await withTestContainer(dao: dao, appEvents: events) {
            let sut = ShoppingModel()
            #expect(await waitUntil { sut.items.count == 1 })

            dao.shoppingLists = [makeList(id: "2", name: "Second")]
            events.shoppingListsChanged()
            #expect(await waitUntil { sut.items.map(\.name) == ["Second"] })

            sut.showAddSheet = true
            let addFetchCount = dao.getShoppingListsCallCount
            await sut.addItem(name: "Third")
            #expect(sut.showAddSheet == false)
            #expect(sut.itemToOpen?.name == "Third")
            #expect(await waitUntil { sut.items.map(\.name).contains("Third") })
            #expect(dao.getShoppingListsCallCount == addFetchCount + 1)

            sut.showAddSheet = true
            await sut.cancelAddingItem()
            #expect(sut.showAddSheet == false)

            let deleteFetchCount = dao.getShoppingListsCallCount
            await sut.deleteItems(offsets: IndexSet(integer: 0))
            #expect(await waitUntil { sut.items.map(\.name).contains("Second") == false })
            #expect(dao.getShoppingListsCallCount == deleteFetchCount + 1)
        }
    }

    @Test("ShoppingModel reports load, add, and delete errors")
    func shoppingModelErrorPaths() async throws {
        let dao = StubDAO()
        let events = SpyAppEventCenter()
        dao.getShoppingListsError = TestFailure.requested("load failed")

        try await withTestContainer(dao: dao, appEvents: events) {
            let sut = ShoppingModel()
            #expect(await waitUntil { events.toasts.count == 1 })
            #expect(events.toasts.last?.title == "Unable to load shopping lists")

            dao.getShoppingListsError = nil
            dao.addShoppingListError = TestFailure.requested("add failed")
            await sut.addItem(name: "List")
            #expect(events.toasts.last?.title == "Unable to create shopping list")

            sut.items = [makeList(id: "1")]
            dao.removeShoppingListError = TestFailure.requested("delete failed")
            await sut.deleteItems(offsets: IndexSet(integer: 0))
            #expect(events.toasts.last?.title == "Unable to delete shopping list")
        }
    }

    @Test("GoodsModel loads, searches, adds, edits, and deletes goods")
    func goodsModelSuccessPaths() async throws {
        let dao = StubDAO()
        let events = SpyAppEventCenter()
        dao.goods = [
            GoodsItemModel(id: "1", name: "Milk", category: "Dairy"),
            GoodsItemModel(id: "2", name: "Bread", category: "Bakery")
        ]

        try await withTestContainer(dao: dao, appEvents: events) {
            let sut = GoodsModel()
            #expect(await waitUntil { sut.items.count == 2 })

            let searchGoodsFetchCount = dao.getGoodsCallCount
            sut.searchString = "mil"
            #expect(await waitUntil { dao.getGoodsCallCount == searchGoodsFetchCount + 1 && sut.items.map(\.name) == ["Milk"] })

            let resetGoodsFetchCount = dao.getGoodsCallCount
            sut.searchString = ""
            #expect(await waitUntil { dao.getGoodsCallCount == resetGoodsFetchCount + 1 && sut.items.count == 2 })
            let addFetchCount = dao.getGoodsCallCount
            await sut.editGood(item: nil, name: "Cheese", category: "Dairy")
            #expect(await waitUntil { dao.getGoodsCallCount == addFetchCount + 1 && sut.items.map(\.name).contains("Cheese") })
            #expect(dao.getGoodsCallCount == addFetchCount + 1)

            let cheese = try #require(sut.items.first { $0.name == "Cheese" })
            let editFetchCount = dao.getGoodsCallCount
            await sut.editGood(item: cheese, name: "Yogurt", category: "Dairy")
            #expect(await waitUntil { dao.getGoodsCallCount == editFetchCount + 1 && sut.items.map(\.name).contains("Yogurt") })
            #expect(dao.getGoodsCallCount == editFetchCount + 1)

            let deleteFetchCount = dao.getGoodsCallCount
            await sut.removeGood(offsets: IndexSet(integer: 0))
            #expect(await waitUntil { dao.getGoodsCallCount == deleteFetchCount + 1 && sut.items.count == 2 })
            #expect(dao.getGoodsCallCount == deleteFetchCount + 1)
        }
    }

    @Test("GoodsModel reports load, save, and delete errors")
    func goodsModelErrorPaths() async throws {
        let dao = StubDAO()
        let events = SpyAppEventCenter()
        dao.getGoodsError = TestFailure.requested("load failed")

        try await withTestContainer(dao: dao, appEvents: events) {
            let sut = GoodsModel()
            #expect(await waitUntil { events.toasts.count == 1 })
            #expect(events.toasts.last?.title == "Unable to load goods")

            dao.getGoodsError = nil
            dao.addGoodError = TestFailure.requested("save failed")
            await sut.editGood(item: nil, name: "Milk", category: "")
            #expect(events.toasts.last?.title == "Unable to save good")

            sut.items = [GoodsItemModel(id: "1", name: "Milk", category: "")]
            dao.removeGoodError = TestFailure.requested("delete failed")
            await sut.removeGood(offsets: IndexSet(integer: 0))
            #expect(events.toasts.last?.title == "Unable to delete good")
        }
    }

    @Test("CategoriesModel loads, searches, saves goods, deletes, and returns goods")
    func categoriesModelSuccessPaths() async throws {
        let dao = StubDAO()
        let events = SpyAppEventCenter()
        let category = CategoriesItemModel(id: "1", name: "Dairy")
        dao.categories = [category]
        dao.categoryGoods[category.id] = [GoodsItemModel(id: "g1", name: "Milk", category: "Dairy")]

        try await withTestContainer(dao: dao, appEvents: events) {
            let sut = CategoriesModel()
            #expect(await waitUntil { sut.items.count == 1 })

            let searchCategoriesFetchCount = dao.getCategoriesCallCount
            sut.searchString = "dai"
            #expect(await waitUntil { dao.getCategoriesCallCount == searchCategoriesFetchCount + 1 && sut.items.map(\.name) == ["Dairy"] })

            let resetCategoriesFetchCount = dao.getCategoriesCallCount
            sut.searchString = ""
            #expect(await waitUntil { dao.getCategoriesCallCount == resetCategoriesFetchCount + 1 && sut.items.count == 1 })
            let saveFetchCount = dao.getCategoriesCallCount
            await sut.editCategory(item: category, name: "Fresh", goods: ["Milk"])
            #expect(await waitUntil { dao.getCategoriesCallCount == saveFetchCount + 1 && sut.items.map(\.name) == ["Fresh"] })
            #expect(dao.savedCategories.last?.2 == ["Milk"])
            #expect(dao.getCategoriesCallCount == saveFetchCount + 1)

            let goods = await sut.getCategoryGoods(category: category)
            #expect(goods.map(\.name) == ["Milk"])

            let deleteFetchCount = dao.getCategoriesCallCount
            await sut.removeStore(offsets: IndexSet(integer: 0))
            #expect(await waitUntil { dao.getCategoriesCallCount == deleteFetchCount + 1 && sut.items.isEmpty })
            #expect(dao.getCategoriesCallCount == deleteFetchCount + 1)
        }
    }

    @Test("CategoriesModel reports load, save, delete, and goods-load errors")
    func categoriesModelErrorPaths() async throws {
        let dao = StubDAO()
        let events = SpyAppEventCenter()
        dao.getCategoriesError = TestFailure.requested("load failed")

        try await withTestContainer(dao: dao, appEvents: events) {
            let sut = CategoriesModel()
            #expect(await waitUntil { events.toasts.count == 1 })
            #expect(events.toasts.last?.title == "Unable to load categories")

            dao.getCategoriesError = nil
            dao.saveCategoryError = TestFailure.requested("save failed")
            await sut.editCategory(item: nil, name: "Dairy", goods: [])
            #expect(events.toasts.last?.title == "Unable to save category")

            sut.items = [CategoriesItemModel(id: "1", name: "Dairy")]
            dao.removeCategoryError = TestFailure.requested("delete failed")
            await sut.removeStore(offsets: IndexSet(integer: 0))
            #expect(events.toasts.last?.title == "Unable to delete category")

            dao.getCategoryGoodsError = TestFailure.requested("goods failed")
            let goods = await sut.getCategoryGoods(category: CategoriesItemModel(id: "1", name: "Dairy"))
            #expect(goods.isEmpty)
            #expect(events.toasts.last?.title == "Unable to load category goods")
        }
    }

    @Test("StoresModel loads, searches, saves categories, deletes, and returns categories")
    func storesModelSuccessPaths() async throws {
        let dao = StubDAO()
        let events = SpyAppEventCenter()
        let store = StoresItemModel(id: "1", name: "Market")
        dao.stores = [store]
        dao.storeCategories[store.id] = [CategoriesItemModel(id: "c1", name: "Dairy")]

        try await withTestContainer(dao: dao, appEvents: events) {
            let sut = StoresModel()
            #expect(await waitUntil { sut.items.count == 1 })

            let searchStoresFetchCount = dao.getStoresCallCount
            sut.searchString = "mar"
            #expect(await waitUntil { dao.getStoresCallCount == searchStoresFetchCount + 1 && sut.items.map(\.name) == ["Market"] })

            let resetStoresFetchCount = dao.getStoresCallCount
            sut.searchString = ""
            #expect(await waitUntil { dao.getStoresCallCount == resetStoresFetchCount + 1 && sut.items.count == 1 })
            let saveFetchCount = dao.getStoresCallCount
            await sut.editStore(item: store, name: "Main", categories: ["Dairy"])
            #expect(await waitUntil { dao.getStoresCallCount == saveFetchCount + 1 && sut.items.map(\.name) == ["Main"] })
            #expect(dao.savedStores.last?.2 == ["Dairy"])
            #expect(dao.getStoresCallCount == saveFetchCount + 1)

            let categories = await sut.getStoreCategories(item: store)
            #expect(categories.map(\.name) == ["Dairy"])

            let deleteFetchCount = dao.getStoresCallCount
            await sut.removeStore(offsets: IndexSet(integer: 0))
            #expect(await waitUntil { dao.getStoresCallCount == deleteFetchCount + 1 && sut.items.isEmpty })
            #expect(dao.getStoresCallCount == deleteFetchCount + 1)
        }
    }

    @Test("StoresModel reports load, save, delete, and category-load errors")
    func storesModelErrorPaths() async throws {
        let dao = StubDAO()
        let events = SpyAppEventCenter()
        dao.getStoresError = TestFailure.requested("load failed")

        try await withTestContainer(dao: dao, appEvents: events) {
            let sut = StoresModel()
            #expect(await waitUntil { events.toasts.count == 1 })
            #expect(events.toasts.last?.title == "Unable to load stores")

            dao.getStoresError = nil
            dao.saveStoreError = TestFailure.requested("save failed")
            await sut.editStore(item: nil, name: "Market", categories: [])
            #expect(events.toasts.last?.title == "Unable to save store")

            sut.items = [StoresItemModel(id: "1", name: "Market")]
            dao.removeStoreError = TestFailure.requested("delete failed")
            await sut.removeStore(offsets: IndexSet(integer: 0))
            #expect(events.toasts.last?.title == "Unable to delete store")

            dao.getStoreCategoriesError = TestFailure.requested("categories failed")
            let categories = await sut.getStoreCategories(item: StoresItemModel(id: "1", name: "Market"))
            #expect(categories.isEmpty)
            #expect(events.toasts.last?.title == "Unable to load store categories")
        }
    }

    @Test("Suggestion models load matching goods and categories")
    func suggestionModelsSuccessPaths() async throws {
        let dao = StubDAO()
        let events = SpyAppEventCenter()
        dao.goods = [GoodsItemModel(id: "1", name: "Milk", category: "Dairy")]
        dao.categories = [CategoriesItemModel(id: "1", name: "Dairy")]
        dao.stores = [StoresItemModel(id: "1", name: "Market")]

        try await withTestContainer(dao: dao, appEvents: events) {
            let goods = AddGoodToCategoryModel()
            goods.itemName = "mil"
            #expect(await waitUntil { goods.goodsNames == ["Milk"] })

            let categories = AddCategoryToStoreModel()
            categories.itemName = "dai"
            #expect(await waitUntil { categories.categoryNames == ["Dairy"] })

            let item = EditShoppingListItemViewModel()
            item.itemName = "mil"
            item.storeName = "mar"
            #expect(await waitUntil { item.goodsNames == ["Milk"] && item.storesNames == ["Market"] })
        }
    }

    @Test("Suggestion models report DAO errors")
    func suggestionModelsErrorPaths() async throws {
        let dao = StubDAO()
        let events = SpyAppEventCenter()
        dao.getGoodsError = TestFailure.requested("goods failed")
        dao.getCategoriesError = TestFailure.requested("categories failed")
        dao.getStoresError = TestFailure.requested("stores failed")

        try await withTestContainer(dao: dao, appEvents: events) {
            let goods = AddGoodToCategoryModel()
            goods.itemName = "mil"
            let categories = AddCategoryToStoreModel()
            categories.itemName = "dai"
            let item = EditShoppingListItemViewModel()
            item.itemName = "milk"
            item.storeName = "market"

            #expect(await waitUntil { events.toasts.count == 4 })
            #expect(events.toasts.map(\.title).contains("Unable to load goods suggestions"))
            #expect(events.toasts.map(\.title).contains("Unable to load category suggestions"))
            #expect(events.toasts.map(\.title).contains("Unable to load store suggestions"))
        }
    }

    @Test("EditShoppingListItemViewModel copies item values and resets defaults")
    func editShoppingListItemViewModelSetItem() async throws {
        try await withTestContainer(dao: StubDAO(), appEvents: SpyAppEventCenter()) {
            let sut = EditShoppingListItemViewModel()
            sut.setItem(makeShoppingItem(title: "Milk", store: "Market", isPurchased: true, amount: "2", isWeight: true, price: "3", isImportant: true, rating: 5))

            #expect(sut.itemName == "Milk")
            #expect(sut.storeName == "Market")
            #expect(sut.amount == "2")
            #expect(sut.amountType == 1)
            #expect(sut.price == "3")
            #expect(sut.isImportant)
            #expect(sut.rating == 5)

            sut.setItem(nil)
            #expect(sut.itemName == "")
            #expect(sut.storeName == "")
            #expect(sut.amount == "")
            #expect(sut.amountType == 0)
            #expect(sut.price == "")
            #expect(sut.isImportant == false)
            #expect(sut.rating == 0)
        }
    }

    @Test("ShoppingListViewModel handles list item actions and sharing")
    func shoppingListViewModelSuccessPaths() async throws {
        let dao = StubDAO()
        let events = SpyAppEventCenter()
        let serializer = StubShoppingListSerializer()
        let list = makeList(id: "list")
        let item = makeShoppingItem(id: "item", title: "Milk")
        dao.shoppingListItems = [item]

        try await withTestContainer(dao: dao, appEvents: events, serializer: serializer) {
            let sut = ShoppingListViewModel()
            sut.listModel = list
            #expect(await waitUntil { sut.output.items.count == 1 })

            let editor = EditShoppingListItemViewModel()
            editor.itemName = "Bread"
            editor.amount = "2"
            editor.price = "3"
            await sut.addShoppingListItem(model: editor)
            #expect(sut.showAddSheet == false)
            #expect(dao.addedShoppingListItems.count == 1)

            await sut.editShoppingListItem(item: item, model: editor)
            #expect(sut.itemToShow == nil)
            #expect(dao.editedShoppingListItems.count == 1)
            #expect(events.dataChangeCount == 2)

            await sut.editItem(item: item)
            #expect(sut.itemToShow?.id == item.id)

            await sut.cancelAddingItem()
            #expect(sut.showAddSheet == false)
            #expect(sut.itemToShow == nil)

            await sut.togglePurchased(item: item)
            #expect(dao.toggledShoppingListItems.count == 1)
            #expect(events.dataChangeCount == 2)

            await sut.removeShoppingListItem(item: item)
            #expect(dao.removedShoppingListItems.count == 1)
            #expect(events.dataChangeCount == 2)

            sut.shareByFile(model: list)
            #expect(await waitUntil { sut.dataToShare != nil && sut.isLoading == false })
            #expect(serializer.exportedLists.map(\.id) == [list.id])
            if let url = sut.dataToShare?.url {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    @Test("ShoppingListViewModel reports missing list and operation errors")
    func shoppingListViewModelErrorPaths() async throws {
        let dao = StubDAO()
        let events = SpyAppEventCenter()
        let serializer = StubShoppingListSerializer()
        let list = makeList(id: "list")
        let item = makeShoppingItem(id: "item", title: "Milk")

        try await withTestContainer(dao: dao, appEvents: events, serializer: serializer) {
            let sut = ShoppingListViewModel()
            let editor = EditShoppingListItemViewModel()
            editor.itemName = "Milk"

            await sut.addShoppingListItem(model: editor)
            await sut.editShoppingListItem(item: item, model: editor)
            await sut.removeShoppingListItem(item: item)
            await sut.togglePurchased(item: item)
            #expect(events.toasts.filter { $0.title == "Shopping list is unavailable" }.count == 4)

            dao.getShoppingListItemsError = TestFailure.requested("load failed")
            sut.listModel = list
            #expect(await waitUntil { events.toasts.last?.title == "Unable to load shopping list" })

            dao.getShoppingListItemsError = nil
            dao.addShoppingListItemError = TestFailure.requested("add failed")
            await sut.addShoppingListItem(model: editor)
            #expect(events.toasts.last?.title == "Unable to add item")

            sut.listModel = list
            dao.editShoppingListItemError = TestFailure.requested("edit failed")
            await sut.editShoppingListItem(item: item, model: editor)
            #expect(events.toasts.last?.title == "Unable to save item")

            dao.removeShoppingListItemError = TestFailure.requested("remove failed")
            await sut.removeShoppingListItem(item: item)
            #expect(events.toasts.last?.title == "Unable to delete item")

            dao.togglePurchasedShoppingListItemError = TestFailure.requested("toggle failed")
            await sut.togglePurchased(item: item)
            #expect(events.toasts.last?.title == "Unable to update item")

            serializer.exportListError = TestFailure.requested("share failed")
            sut.shareByFile(model: list)
            #expect(await waitUntil { events.toasts.last?.title == "Unable to prepare export" })
            #expect(sut.isLoading == false)
        }
    }

    @Test("AboutModel creates backups and reports empty or failing backup work")
    func aboutModelPaths() async throws {
        let dao = StubDAO()
        let events = SpyAppEventCenter()
        let serializer = StubShoppingListSerializer()
        dao.shoppingLists = [makeList(id: "list", name: "Groceries")]

        try await withTestContainer(dao: dao, appEvents: events, serializer: serializer) {
            let sut = AboutModel()
            sut.makeBackup()
            #expect(await waitUntil { sut.dataToShare != nil && sut.isLoading == false })
            #expect(serializer.exportedBackups.first?.map(\.name) == ["Groceries"])
            if let url = sut.dataToShare?.url {
                try? FileManager.default.removeItem(at: url)
            }

            dao.shoppingLists = []
            sut.dataToShare = nil
            sut.makeBackup()
            #expect(await waitUntil { events.toasts.last?.title == "Nothing to back up" })

            dao.shoppingLists = [makeList(id: "list")]
            dao.getShoppingListsError = TestFailure.requested("load failed")
            sut.makeBackup()
            #expect(await waitUntil { events.toasts.last?.title == "Unable to create backup" })

            dao.getShoppingListsError = nil
            serializer.exportBackupError = TestFailure.requested("export failed")
            sut.makeBackup()
            #expect(await waitUntil { events.toasts.last?.title == "Unable to create backup" })
            #expect(sut.isLoading == false)
        }
    }
}
