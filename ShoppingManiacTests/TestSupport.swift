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

final class SpyAppEventCenter: AppEventCenterProtocol, @unchecked Sendable {
    private let shoppingListsSubject = PassthroughSubject<Void, Never>()
    private let toastSubject = PassthroughSubject<ToastMessage, Never>()

    private(set) var shoppingListsChangeCount = 0
    private(set) var toasts: [ToastMessage] = []

    var shoppingListsDidChange: AnyPublisher<Void, Never> {
        shoppingListsSubject.eraseToAnyPublisher()
    }

    var toastMessages: AnyPublisher<ToastMessage, Never> {
        toastSubject.eraseToAnyPublisher()
    }

    func shoppingListsChanged() {
        shoppingListsChangeCount += 1
        shoppingListsSubject.send()
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

final class StubDAO: DAOProtocol, @unchecked Sendable {
    var shoppingLists: [ShoppingListModel] = []
    var shoppingListItems: [ShoppingListItemModel] = []
    var goods: [GoodsItemModel] = []
    var categories: [CategoriesItemModel] = []
    var stores: [StoresItemModel] = []
    var categoryGoods: [String: [GoodsItemModel]] = [:]
    var storeCategories: [String: [CategoriesItemModel]] = [:]

    var getShoppingListsError: Error?
    var addShoppingListError: Error?
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
    var removeCategoryError: Error?
    var getCategoryGoodsError: Error?
    var syncCategoryGoodsError: Error?
    var getStoresError: Error?
    var addStoreError: Error?
    var editStoreError: Error?
    var removeStoreError: Error?
    var getStoreCategoriesError: Error?
    var syncStoreCategoriesError: Error?

    private(set) var addedShoppingListItems: [(ShoppingListModel, String, String, String, Bool, String, Bool, Int, Bool, String?)] = []
    private(set) var editedShoppingListItems: [(ShoppingListItemModel, String, String, String, Bool, String, Bool, Int)] = []
    private(set) var removedShoppingListItems: [ShoppingListItemModel] = []
    private(set) var toggledShoppingListItems: [ShoppingListItemModel] = []
    private(set) var syncedCategoryGoods: [(CategoriesItemModel, [String])] = []
    private(set) var syncedStoreCategories: [(StoresItemModel, [String])] = []

    func getShoppingLists() async throws -> [ShoppingListModel] {
        if let getShoppingListsError { throw getShoppingListsError }
        return shoppingLists
    }

    func addShoppingList(name: String, date: Date, uniqueId: String?) async throws -> ShoppingListModel {
        if let addShoppingListError { throw addShoppingListError }
        let list = ShoppingListModel(id: UUID().uuidString, uniqueId: uniqueId ?? UUID().uuidString, name: name, date: date)
        shoppingLists.append(list)
        return list
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
        isPurchased: Bool,
        uniqueId: String?
    ) async throws {
        if let addShoppingListItemError { throw addShoppingListItemError }
        addedShoppingListItems.append((list, name, amount, store, isWeight, price, isImportant, rating, isPurchased, uniqueId))
        shoppingListItems.append(ShoppingListItemModel(
            id: UUID().uuidString,
            uniqueId: uniqueId ?? UUID().uuidString,
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
                uniqueId: current.uniqueId,
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

    func getGoods(search: String) async throws -> [GoodsItemModel] {
        if let getGoodsError { throw getGoodsError }
        return search.isEmpty ? goods : goods.filter { $0.name.localizedCaseInsensitiveContains(search) }
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

    func getCategories(search: String) async throws -> [CategoriesItemModel] {
        if let getCategoriesError { throw getCategoriesError }
        return search.isEmpty ? categories : categories.filter { $0.name.localizedCaseInsensitiveContains(search) }
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

    func getStores(search: String) async throws -> [StoresItemModel] {
        if let getStoresError { throw getStoresError }
        return search.isEmpty ? stores : stores.filter { $0.name.localizedCaseInsensitiveContains(search) }
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

final class StubShoppingListSerializer: ShoppingListSerializerProtocol, @unchecked Sendable {
    var exportListData = Data("list".utf8)
    var exportBackupData = Data("backup".utf8)
    var importedList = ShoppingListModel(id: "imported", uniqueId: "imported-unique", name: "Imported", date: Date(timeIntervalSince1970: 0))
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

final class TestContextProvider: ContextProviderProtocol, @unchecked Sendable {
    let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    func getContext() -> ModelContext {
        ModelContext(container)
    }
}

func makeInMemoryContainer() throws -> ModelContainer {
    let schema = Schema([
        ShoppingList.self,
        ShoppingListItem.self,
        Good.self,
        Category.self,
        Store.self,
        CategoryStoreOrder.self,
        GoodRating.self,
        Picture.self
    ])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
    return try ModelContainer(for: schema, configurations: [configuration])
}

@discardableResult
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
    uniqueId: String = UUID().uuidString,
    name: String = "Groceries",
    date: Date = Date(timeIntervalSince1970: 1_000)
) -> ShoppingListModel {
    ShoppingListModel(id: id, uniqueId: uniqueId, name: name, date: date)
}

func makeShoppingItem(
    id: String = UUID().uuidString,
    uniqueId: String = UUID().uuidString,
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
        uniqueId: uniqueId,
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
