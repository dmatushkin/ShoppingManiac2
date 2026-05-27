import Combine
import FactoryKit
import Foundation
import SwiftData
import Testing
@testable import ShoppingManiac

enum TestFailure: Error, Equatable, LocalizedError {
    case requested(String)

    var errorDescription: String? {
        switch self {
        case .requested(let message):
            message
        }
    }
}

@MainActor
final class SpyAppEventCenter: AppEventCenterProtocol {
    private let shoppingListsSubject = PassthroughSubject<Void, Never>()
    private let dataSubject = PassthroughSubject<Void, Never>()
    private let toastSubject = PassthroughSubject<ToastMessage, Never>()

    private(set) var shoppingListsChangeCount = 0
    private(set) var dataChangeCount = 0
    private(set) var toasts: [ToastMessage] = []

    var shoppingListsDidChange: AnyPublisher<Void, Never> {
        shoppingListsSubject.eraseToAnyPublisher()
    }

    var dataDidChange: AnyPublisher<Void, Never> {
        dataSubject.eraseToAnyPublisher()
    }

    var toastMessages: AnyPublisher<ToastMessage, Never> {
        toastSubject.eraseToAnyPublisher()
    }

    func shoppingListsChanged() {
        shoppingListsChangeCount += 1
        shoppingListsSubject.send()
        dataChanged()
    }

    func dataChanged() {
        dataChangeCount += 1
        dataSubject.send()
    }

    func showToast(_ message: ToastMessage) {
        toasts.append(message)
        toastSubject.send(message)
    }

    func showSuccess(_ title: String, detail: String?) {
        showToast(.success(title, detail: detail))
    }

    func showError(_ title: String, detail: String?) {
        showToast(.error(title, detail: detail))
    }

    func showError(_ error: Error, fallback: String) {
        showError(fallback, detail: (error as NSError).localizedDescription.nilIfEmpty)
    }
}

@MainActor
final class StubDAO: DAOProtocol {
    var shoppingLists: [ShoppingListModel] = []
    var shoppingListItems: [ShoppingListItemModel] = []
    var goods: [GoodsItemModel] = []
    var categories: [CategoriesItemModel] = []
    var stores: [StoresItemModel] = []
    var categoryGoods: [String: [GoodsItemModel]] = [:]
    var storeCategories: [String: [CategoriesItemModel]] = [:]

    var getShoppingListsError: Error?
    var addShoppingListError: Error?
    var importShoppingListError: Error?
    var removeShoppingListError: Error?
    var getShoppingListItemsError: Error?
    var addShoppingListItemError: Error?
    var editShoppingListItemError: Error?
    var removeShoppingListItemError: Error?
    var togglePurchasedShoppingListItemError: Error?
    var getGoodsError: Error?
    var addGoodError: Error?
    var editGoodError: Error?
    var removeGoodError: Error?
    var getCategoriesError: Error?
    var addCategoryError: Error?
    var editCategoryError: Error?
    var saveCategoryError: Error?
    var removeCategoryError: Error?
    var getCategoryGoodsError: Error?
    var syncCategoryGoodsError: Error?
    var getStoresError: Error?
    var addStoreError: Error?
    var editStoreError: Error?
    var saveStoreError: Error?
    var removeStoreError: Error?
    var getStoreCategoriesError: Error?
    var syncStoreCategoriesError: Error?

    private(set) var addedShoppingListItems: [(ShoppingListModel, String, String, String, Bool, String, Bool, Int, Bool)] = []
    private(set) var importedShoppingLists: [(String, Date, [ShoppingListImportItem])] = []
    private(set) var editedShoppingListItems: [(ShoppingListItemModel, String, String, String, Bool, String, Bool, Int)] = []
    private(set) var removedShoppingListItems: [ShoppingListItemModel] = []
    private(set) var toggledShoppingListItems: [ShoppingListItemModel] = []
    private(set) var syncedCategoryGoods: [(CategoriesItemModel, [String])] = []
    private(set) var savedCategories: [(CategoriesItemModel?, String, [String])] = []
    private(set) var syncedStoreCategories: [(StoresItemModel, [String])] = []
    private(set) var savedStores: [(StoresItemModel?, String, [String])] = []
    private(set) var getShoppingListsCallCount = 0
    private(set) var getGoodsCallCount = 0
    private(set) var getCategoriesCallCount = 0
    private(set) var getStoresCallCount = 0

    func getShoppingLists() async throws -> [ShoppingListModel] {
        getShoppingListsCallCount += 1
        if let getShoppingListsError { throw getShoppingListsError }
        return shoppingLists
    }

    func addShoppingList(name: String, date: Date) async throws -> ShoppingListModel {
        if let addShoppingListError { throw addShoppingListError }
        let list = ShoppingListModel(id: UUID().uuidString, name: name, date: date)
        shoppingLists.append(list)
        return list
    }

    func importShoppingList(name: String, date: Date, items: [ShoppingListImportItem]) async throws -> ShoppingListModel {
        guard let list = try await importShoppingLists([ShoppingListImport(name: name, date: date, items: items)]).first else {
            throw TestFailure.requested("import failed")
        }
        return list
    }

    func importShoppingLists(_ lists: [ShoppingListImport]) async throws -> [ShoppingListModel] {
        if let importShoppingListError { throw importShoppingListError }
        var imported: [ShoppingListModel] = []
        imported.reserveCapacity(lists.count)
        for importModel in lists {
            importedShoppingLists.append((importModel.name, importModel.date, importModel.items))
            let list = ShoppingListModel(id: UUID().uuidString, name: importModel.name, date: importModel.date)
            shoppingLists.append(list)
            imported.append(list)
            for item in importModel.items {
                shoppingListItems.append(ShoppingListItemModel(
                    id: UUID().uuidString,
                    title: item.name,
                    store: item.store,
                    category: "",
                    categoryStoreOrder: nil,
                    isPurchased: item.isPurchased,
                    amount: "\(item.amount)",
                    isWeight: item.isWeight,
                    price: "\(item.price)",
                    isImportant: item.isImportant,
                    rating: 0
                ))
            }
        }
        return imported
    }

    func removeShoppingList(_ item: ShoppingListModel) async throws {
        if let removeShoppingListError { throw removeShoppingListError }
        shoppingLists.removeAll { $0.id == item.id }
    }

    func getShoppingListItems(list: ShoppingListModel) async throws -> [ShoppingListItemModel] {
        if let getShoppingListItemsError { throw getShoppingListItemsError }
        return shoppingListItems
    }

    func addShoppingListItem(
        list: ShoppingListModel,
        name: String,
        amount: String,
        store: String,
        isWeight: Bool,
        price: String,
        isImportant: Bool,
        rating: Int,
        isPurchased: Bool
    ) async throws {
        if let addShoppingListItemError { throw addShoppingListItemError }
        addedShoppingListItems.append((list, name, amount, store, isWeight, price, isImportant, rating, isPurchased))
        shoppingListItems.append(ShoppingListItemModel(
            id: UUID().uuidString,
            title: name,
            store: store,
            category: "",
            categoryStoreOrder: nil,
            isPurchased: isPurchased,
            amount: amount,
            isWeight: isWeight,
            price: price,
            isImportant: isImportant,
            rating: rating
        ))
    }

    func editShoppingListItem(
        item: ShoppingListItemModel,
        name: String,
        amount: String,
        store: String,
        isWeight: Bool,
        price: String,
        isImportant: Bool,
        rating: Int
    ) async throws {
        if let editShoppingListItemError { throw editShoppingListItemError }
        editedShoppingListItems.append((item, name, amount, store, isWeight, price, isImportant, rating))
    }

    func removeShoppingListItem(item: ShoppingListItemModel) async throws {
        if let removeShoppingListItemError { throw removeShoppingListItemError }
        removedShoppingListItems.append(item)
        shoppingListItems.removeAll { $0.id == item.id }
    }

    func togglePurchasedShoppingListItem(item: ShoppingListItemModel) async throws {
        if let togglePurchasedShoppingListItemError { throw togglePurchasedShoppingListItemError }
        toggledShoppingListItems.append(item)
        shoppingListItems = shoppingListItems.map { current in
            guard current.id == item.id else { return current }
            return ShoppingListItemModel(
                id: current.id,
                title: current.title,
                store: current.store,
                category: current.category,
                categoryStoreOrder: current.categoryStoreOrder,
                isPurchased: current.isPurchased == false,
                amount: current.amount,
                isWeight: current.isWeight,
                price: current.price,
                isImportant: current.isImportant,
                rating: current.rating
            )
        }
    }

    func getGoods(search: String, limit: Int?) async throws -> [GoodsItemModel] {
        getGoodsCallCount += 1
        if let getGoodsError { throw getGoodsError }
        let result = search.isEmpty ? goods : goods.filter { $0.name.localizedCaseInsensitiveContains(search) }
        return limit.map { Array(result.prefix($0)) } ?? result
    }

    func addGood(name: String, category: String) async throws -> GoodsItemModel {
        if let addGoodError { throw addGoodError }
        let item = GoodsItemModel(id: UUID().uuidString, name: name, category: category)
        goods.append(item)
        return item
    }

    func editGood(item: GoodsItemModel, name: String, category: String) async throws -> GoodsItemModel {
        if let editGoodError { throw editGoodError }
        let edited = GoodsItemModel(id: item.id, name: name, category: category)
        goods = goods.map { $0.id == item.id ? edited : $0 }
        return edited
    }

    func removeGood(item: GoodsItemModel) async throws {
        if let removeGoodError { throw removeGoodError }
        goods.removeAll { $0.id == item.id }
    }

    func getCategories(search: String, limit: Int?) async throws -> [CategoriesItemModel] {
        getCategoriesCallCount += 1
        if let getCategoriesError { throw getCategoriesError }
        let result = search.isEmpty ? categories : categories.filter { $0.name.localizedCaseInsensitiveContains(search) }
        return limit.map { Array(result.prefix($0)) } ?? result
    }

    func addCategory(name: String) async throws -> CategoriesItemModel {
        if let addCategoryError { throw addCategoryError }
        let item = CategoriesItemModel(id: UUID().uuidString, name: name)
        categories.append(item)
        return item
    }

    func editCategory(item: CategoriesItemModel, name: String) async throws -> CategoriesItemModel {
        if let editCategoryError { throw editCategoryError }
        let edited = CategoriesItemModel(id: item.id, name: name)
        categories = categories.map { $0.id == item.id ? edited : $0 }
        return edited
    }

    func saveCategory(item: CategoriesItemModel?, name: String, goods: [String]) async throws -> CategoriesItemModel {
        if let saveCategoryError { throw saveCategoryError }
        savedCategories.append((item, name, goods))
        let category: CategoriesItemModel
        if let item {
            category = try await editCategory(item: item, name: name)
        } else {
            category = try await addCategory(name: name)
        }
        categoryGoods[category.id] = goods.map { GoodsItemModel(id: UUID().uuidString, name: $0, category: category.name) }
        return category
    }

    func removeCategory(item: CategoriesItemModel) async throws {
        if let removeCategoryError { throw removeCategoryError }
        categories.removeAll { $0.id == item.id }
    }

    func getCategoryGoods(item: CategoriesItemModel) async throws -> [GoodsItemModel] {
        if let getCategoryGoodsError { throw getCategoryGoodsError }
        return categoryGoods[item.id] ?? []
    }

    func syncCategoryGoods(item: CategoriesItemModel, goods: [String]) async throws {
        if let syncCategoryGoodsError { throw syncCategoryGoodsError }
        syncedCategoryGoods.append((item, goods))
    }

    func getStores(search: String, limit: Int?) async throws -> [StoresItemModel] {
        getStoresCallCount += 1
        if let getStoresError { throw getStoresError }
        let result = search.isEmpty ? stores : stores.filter { $0.name.localizedCaseInsensitiveContains(search) }
        return limit.map { Array(result.prefix($0)) } ?? result
    }

    func addStore(name: String) async throws -> StoresItemModel {
        if let addStoreError { throw addStoreError }
        let item = StoresItemModel(id: UUID().uuidString, name: name)
        stores.append(item)
        return item
    }

    func editStore(item: StoresItemModel, name: String) async throws -> StoresItemModel {
        if let editStoreError { throw editStoreError }
        let edited = StoresItemModel(id: item.id, name: name)
        stores = stores.map { $0.id == item.id ? edited : $0 }
        return edited
    }

    func saveStore(item: StoresItemModel?, name: String, categories: [String]) async throws -> StoresItemModel {
        if let saveStoreError { throw saveStoreError }
        savedStores.append((item, name, categories))
        let store: StoresItemModel
        if let item {
            store = try await editStore(item: item, name: name)
        } else {
            store = try await addStore(name: name)
        }
        storeCategories[store.id] = categories.map { CategoriesItemModel(id: UUID().uuidString, name: $0) }
        return store
    }

    func removeStore(item: StoresItemModel) async throws {
        if let removeStoreError { throw removeStoreError }
        stores.removeAll { $0.id == item.id }
    }

    func getStoreCategories(item: StoresItemModel) async throws -> [CategoriesItemModel] {
        if let getStoreCategoriesError { throw getStoreCategoriesError }
        return storeCategories[item.id] ?? []
    }

    func syncStoreCategories(item: StoresItemModel, categories: [String]) async throws {
        if let syncStoreCategoriesError { throw syncStoreCategoriesError }
        syncedStoreCategories.append((item, categories))
    }
}

@MainActor
final class StubShoppingListSerializer: ShoppingListSerializerProtocol {
    var exportListData = Data("list".utf8)
    var exportBackupData = Data("backup".utf8)
    var importedList = ShoppingListModel(id: "imported", name: "Imported", date: Date(timeIntervalSince1970: 0))
    var importedBackup: [ShoppingListModel] = []

    var exportListError: Error?
    var importListError: Error?
    var exportBackupError: Error?
    var importBackupError: Error?

    private(set) var exportedLists: [ShoppingListModel] = []
    private(set) var importedListData: [Data] = []
    private(set) var exportedBackups: [[ShoppingListModel]] = []
    private(set) var importedBackupData: [Data] = []

    func exportList(listModel: ShoppingListModel) async throws -> Data {
        if let exportListError { throw exportListError }
        exportedLists.append(listModel)
        return exportListData
    }

    func importList(data: Data) async throws -> ShoppingListModel {
        if let importListError { throw importListError }
        importedListData.append(data)
        return importedList
    }

    func exportBackup(lists: [ShoppingListModel]) async throws -> Data {
        if let exportBackupError { throw exportBackupError }
        exportedBackups.append(lists)
        return exportBackupData
    }

    func importBackup(data: Data) async throws -> [ShoppingListModel] {
        if let importBackupError { throw importBackupError }
        importedBackupData.append(data)
        return importedBackup
    }
}

@MainActor
final class TestContextProvider: ContextProviderProtocol {
    let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    func getContext() -> ModelContext {
        ModelContext(container)
    }
}

func makeInMemoryContainer() throws -> ModelContainer {
    let schema = ShoppingManiacSchema.current
    let configuration = ModelConfiguration(
        UUID().uuidString,
        schema: schema,
        isStoredInMemoryOnly: true,
        cloudKitDatabase: .none
    )
    return try ModelContainer(for: schema, migrationPlan: ShoppingManiacMigrationPlan.self, configurations: [configuration])
}

func makeFileBackedContainer(url: URL) throws -> ModelContainer {
    let schema = ShoppingManiacSchema.current
    let configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
    return try ModelContainer(for: schema, migrationPlan: ShoppingManiacMigrationPlan.self, configurations: [configuration])
}

@discardableResult
@MainActor
func withTestContainer<T>(
    dao: DAOProtocol? = nil,
    appEvents: AppEventCenterProtocol? = nil,
    serializer: ShoppingListSerializerProtocol? = nil,
    contextProvider: ContextProviderProtocol? = nil,
    operation: @escaping () async throws -> T
) async throws -> T {
    let container = Container()
    return try await Scope.$singleton.withValue(Scope.singleton.clone()) {
        try await Container.$shared.withValue(container) {
            if let dao {
                Container.shared.dao.register { dao }
            }
            if let appEvents {
                Container.shared.appEventCenter.register { appEvents }
            }
            if let serializer {
                Container.shared.shoppingListSerializer.register { serializer }
            }
            if let contextProvider {
                Container.shared.contextProvider.register { contextProvider }
            }
            return try await operation()
        }
    }
}

@MainActor
func waitUntil(
    timeoutNanoseconds: UInt64 = 1_000_000_000,
    condition: @escaping @MainActor () -> Bool
) async -> Bool {
    let interval: UInt64 = 10_000_000
    var elapsed: UInt64 = 0
    while elapsed < timeoutNanoseconds {
        if condition() {
            return true
        }
        try? await Task.sleep(nanoseconds: interval)
        elapsed += interval
    }
    return condition()
}

func expectDBError(
    _ expected: DAO.DBError,
    sourceLocation: SourceLocation = #_sourceLocation,
    operation: () async throws -> Void
) async {
    do {
        try await operation()
        Issue.record("Expected \(expected) to be thrown.", sourceLocation: sourceLocation)
    } catch let error as DAO.DBError {
        #expect(String(describing: error) == String(describing: expected), sourceLocation: sourceLocation)
    } catch {
        Issue.record("Expected \(expected), got \(error).", sourceLocation: sourceLocation)
    }
}

func expectTestFailure(
    _ expected: TestFailure,
    sourceLocation: SourceLocation = #_sourceLocation,
    operation: () async throws -> Void
) async {
    do {
        try await operation()
        Issue.record("Expected \(expected) to be thrown.", sourceLocation: sourceLocation)
    } catch let error as TestFailure {
        #expect(error == expected, sourceLocation: sourceLocation)
    } catch {
        Issue.record("Expected \(expected), got \(error).", sourceLocation: sourceLocation)
    }
}

func makeList(
    id: String = UUID().uuidString,
    name: String = "Groceries",
    date: Date = Date(timeIntervalSince1970: 1_000)
) -> ShoppingListModel {
    ShoppingListModel(id: id, name: name, date: date)
}

func makeShoppingItem(
    id: String = UUID().uuidString,
    title: String = "Milk",
    store: String = "",
    category: String = "",
    categoryStoreOrder: Int? = nil,
    isPurchased: Bool = false,
    amount: String = "1",
    isWeight: Bool = false,
    price: String = "0",
    isImportant: Bool = false,
    rating: Int = 0
) -> ShoppingListItemModel {
    ShoppingListItemModel(
        id: id,
        title: title,
        store: store,
        category: category,
        categoryStoreOrder: categoryStoreOrder,
        isPurchased: isPurchased,
        amount: amount,
        isWeight: isWeight,
        price: price,
        isImportant: isImportant,
        rating: rating
    )
}
