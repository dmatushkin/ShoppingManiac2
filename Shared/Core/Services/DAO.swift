//
//  DAO.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 10.10.2021.
//

import Foundation
import Factory
import CommonError
import SwiftData

protocol DAOProtocol: Sendable {
    func getShoppingLists() async throws -> [ShoppingListModel]
    func addShoppingList(name: String, date: Date, uniqueId: String?) async throws -> ShoppingListModel
    func removeShoppingList(_ item: ShoppingListModel) async throws
    func getShoppingListItems(list: ShoppingListModel) async throws -> [ShoppingListItemModel]
    func addShoppingListItem(list: ShoppingListModel,
                             name: String,
                             amount: String,
                             store: String,
                             isWeight: Bool,
                             price: String,
                             isImportant: Bool,
                             rating: Int,
                             isPurchased: Bool,
                             uniqueId: String?) async throws
    func editShoppingListItem(item: ShoppingListItemModel,
                              name: String,
                              amount: String,
                              store: String,
                              isWeight: Bool,
                              price: String,
                              isImportant: Bool,
                              rating: Int) async throws
    func removeShoppingListItem(item: ShoppingListItemModel) async throws
    func togglePurchasedShoppingListItem(item: ShoppingListItemModel) async throws
    func getGoods(search: String) async throws -> [GoodsItemModel]
    func addGood(name: String, category: String) async throws -> GoodsItemModel
    func editGood(item: GoodsItemModel, name: String, category: String) async throws -> GoodsItemModel
    func removeGood(item: GoodsItemModel) async throws
    func getCategories(search: String) async throws -> [CategoriesItemModel]
    func addCategory(name: String) async throws -> CategoriesItemModel
    func editCategory(item: CategoriesItemModel, name: String) async throws -> CategoriesItemModel
    func removeCategory(item: CategoriesItemModel) async throws
    func getCategoryGoods(item: CategoriesItemModel) async throws -> [GoodsItemModel]
    func syncCategoryGoods(item: CategoriesItemModel, goods: [String]) async throws
    func getStores(search: String) async throws -> [StoresItemModel]
    func addStore(name: String) async throws -> StoresItemModel
    func editStore(item: StoresItemModel, name: String) async throws -> StoresItemModel
    func removeStore(item: StoresItemModel) async throws
    func getStoreCategories(item: StoresItemModel) async throws -> [CategoriesItemModel]
    func syncStoreCategories(item: StoresItemModel, categories: [String]) async throws
}

final class DAO: DAOProtocol, @unchecked Sendable {
    enum DBError: Error {
        case unableToCreateShoppingList
        case unableToGetShoppingList
        case unableToCreateShoppingItem
        case unableToGetShoppingItem
        case unableToCreateGood
        case unableToGetGood
        case unableToCreateCategory
        case unableToGetCategory
        case unableToCreateStore
        case unableToGetStore
        case unableToCreateOder
        case unableToGetOrder
    }

    @Injected(\.contextProvider) private var contextProvider: ContextProviderProtocol

    required init() {}
    
    private static func persistentIDString<T: PersistentModel>(_ model: T) -> String {
        String(describing: model.persistentModelID.id)
    }

    private static func normalizedName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func normalizedNames(_ names: [String]) -> [String] {
        var seenNames = Set<String>()
        return names
            .map(normalizedName)
            .filter { !$0.isEmpty }
            .filter { seenNames.insert($0.localizedLowercase).inserted }
    }
    
    private func fetchModel<T: PersistentModel>(id: String, context: ModelContext, as type: T.Type) throws -> T? {
        let descriptor = FetchDescriptor<T>()
        return try context.fetch(descriptor).first { Self.persistentIDString($0) == id }
    }
    
    func getShoppingLists() async throws -> [ShoppingListModel] {
        let context = contextProvider.getContext()
        let descriptor = FetchDescriptor<ShoppingList>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        return try context.fetch(descriptor)
            .filter { !$0.isRemoved }
            .map(Self.makeShoppingListModel)
    }
    
    func addShoppingList(name: String, date: Date, uniqueId: String?) async throws -> ShoppingListModel {
        let context = contextProvider.getContext()
        let resolvedUniqueId = uniqueId?.nilIfEmpty ?? UUID().uuidString
        let item = try createOrGetShoppingList(uniqueId: uniqueId, context: context)
        item.name = Self.normalizedName(name)
        item.date = date
        item.uniqueId = resolvedUniqueId
        item.isRemoved = false
        try context.save()
        return Self.makeShoppingListModel(item)
    }
    
    private func createOrGetShoppingList(uniqueId: String?, context: ModelContext) throws -> ShoppingList {
        if let uniqueId = uniqueId?.nilIfEmpty,
           let existing = try fetchShoppingList(uniqueId: uniqueId, context: context) {
            return existing
        }
        let item = ShoppingList()
        context.insert(item)
        return item
    }
    
    private func fetchShoppingList(uniqueId: String, context: ModelContext) throws -> ShoppingList? {
        var descriptor = FetchDescriptor<ShoppingList>(predicate: #Predicate { $0.uniqueId == uniqueId })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
    
    private func fetchShoppingList(id: String, context: ModelContext) throws -> ShoppingList? {
        try fetchModel(id: id, context: context, as: ShoppingList.self)
    }
    
    func removeShoppingList(_ item: ShoppingListModel) async throws {
        let context = contextProvider.getContext()
        guard let item = try fetchShoppingList(id: item.id, context: context) else { throw DBError.unableToGetShoppingList }
        item.isRemoved = true
        try context.save()
    }
    
    func getShoppingListItems(list: ShoppingListModel) async throws -> [ShoppingListItemModel] {
        let context = contextProvider.getContext()
        guard let list = try fetchShoppingList(id: list.id, context: context) else { throw DBError.unableToGetShoppingList }
        let listPersistentID = list.persistentModelID
        let descriptor = FetchDescriptor<ShoppingListItem>(predicate: #Predicate { !$0.isRemoved })
        let numberFormatter = NumberFormatter()
        return try context.fetch(descriptor).filter { item in
            item.list?.persistentModelID == listPersistentID
        }.map { item in
            let orders = item.good?.category?.orders ?? []
            let order = orders.first(where: { $0.store?.persistentModelID == item.store?.persistentModelID })?.order
            numberFormatter.maximumFractionDigits = item.isWeight ? 2 : 0
            let amount = numberFormatter.string(from: NSNumber(value: item.quantity)) ?? ""
            return ShoppingListItemModel(id: Self.persistentIDString(item),
                                         uniqueId: item.uniqueId,
                                         title: item.good?.name ?? "",
                                         store: item.store?.name ?? "",
                                         category: item.good?.category?.name ?? "",
                                         categoryStoreOrder: order,
                                         isPurchased: item.purchased,
                                         amount: amount,
                                         isWeight: item.isWeight,
                                         price: "\(item.price)",
                                         isImportant: item.isImportant,
                                         rating: item.good?.personalRating ?? 0)
        }
    }
    
    func addShoppingListItem(list: ShoppingListModel,
                             name: String,
                             amount: String,
                             store: String,
                             isWeight: Bool,
                             price: String,
                             isImportant: Bool,
                             rating: Int,
                             isPurchased: Bool,
                             uniqueId: String?) async throws {
        let context = contextProvider.getContext()
        let resolvedName = Self.normalizedName(name)
        let resolvedStore = Self.normalizedName(store)
        guard !resolvedName.isEmpty, let shoppingList = try fetchShoppingList(id: list.id, context: context) else { throw DBError.unableToGetShoppingList }
        let item = try createOrGetShoppingListItem(uniqueId: uniqueId, context: context)
        let resolvedUniqueId = uniqueId?.nilIfEmpty ?? UUID().uuidString
        let numberFormatter = NumberFormatter()
        item.list = shoppingList
        item.good = try createOrGetGood(name: resolvedName, context: context)
        item.good?.personalRating = rating
        item.quantity = numberFormatter.number(from: amount)?.floatValue ?? 1
        item.isWeight = isWeight
        item.price = numberFormatter.number(from: price)?.floatValue ?? 0
        item.isImportant = isImportant
        item.uniqueId = resolvedUniqueId
        item.purchased = isPurchased
        item.isRemoved = false
        item.store = resolvedStore.isEmpty ? nil : try createOrGetStore(name: resolvedStore, context: context)
        try context.save()
    }
    
    private func createOrGetShoppingListItem(uniqueId: String?, context: ModelContext) throws -> ShoppingListItem {
        if let uniqueId = uniqueId?.nilIfEmpty,
           let existing = try fetchShoppingListItem(uniqueId: uniqueId, context: context) {
            return existing
        }
        let item = ShoppingListItem()
        context.insert(item)
        return item
    }
    
    private func fetchShoppingListItem(uniqueId: String, context: ModelContext) throws -> ShoppingListItem? {
        var descriptor = FetchDescriptor<ShoppingListItem>(predicate: #Predicate { $0.uniqueId == uniqueId })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
    
    private func fetchShoppingListItem(id: String, context: ModelContext) throws -> ShoppingListItem? {
        try fetchModel(id: id, context: context, as: ShoppingListItem.self)
    }
    
    func editShoppingListItem(item: ShoppingListItemModel,
                              name: String,
                              amount: String,
                              store: String,
                              isWeight: Bool,
                              price: String,
                              isImportant: Bool,
                              rating: Int) async throws {
        let context = contextProvider.getContext()
        let resolvedName = Self.normalizedName(name)
        let resolvedStore = Self.normalizedName(store)
        guard !resolvedName.isEmpty, let shoppingItem = try fetchShoppingListItem(id: item.id, context: context) else { throw DBError.unableToGetShoppingItem }
        let numberFormatter = NumberFormatter()
        shoppingItem.good = try createOrGetGood(name: resolvedName, context: context)
        shoppingItem.good?.personalRating = rating
        shoppingItem.quantity = numberFormatter.number(from: amount)?.floatValue ?? 1
        shoppingItem.isWeight = isWeight
        shoppingItem.price = numberFormatter.number(from: price)?.floatValue ?? 0
        shoppingItem.isImportant = isImportant
        shoppingItem.store = resolvedStore.isEmpty ? nil : try createOrGetStore(name: resolvedStore, context: context)
        try context.save()
    }
    
    private func createOrGetGood(name: String, context: ModelContext) throws -> Good {
        let resolvedName = Self.normalizedName(name)
        if let good = try fetchGood(name: resolvedName, context: context) {
            return good
        }
        let good = Good(name: resolvedName)
        context.insert(good)
        return good
    }
    
    private func fetchGood(name: String, context: ModelContext) throws -> Good? {
        var descriptor = FetchDescriptor<Good>(predicate: #Predicate { $0.name == name })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
    
    private func fetchGood(id: String, context: ModelContext) throws -> Good? {
        try fetchModel(id: id, context: context, as: Good.self)
    }
    
    private func createOrGetStore(name: String, context: ModelContext) throws -> Store {
        let resolvedName = Self.normalizedName(name)
        if let store = try fetchStore(name: resolvedName, context: context) {
            return store
        }
        let store = Store(name: resolvedName)
        context.insert(store)
        return store
    }
    
    private func fetchStore(name: String, context: ModelContext) throws -> Store? {
        var descriptor = FetchDescriptor<Store>(predicate: #Predicate { $0.name == name })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
    
    private func fetchStore(id: String, context: ModelContext) throws -> Store? {
        try fetchModel(id: id, context: context, as: Store.self)
    }
    
    func removeShoppingListItem(item: ShoppingListItemModel) async throws {
        let context = contextProvider.getContext()
        guard let shoppingItem = try fetchShoppingListItem(id: item.id, context: context) else { throw DBError.unableToGetShoppingItem }
        shoppingItem.isRemoved = true
        try context.save()
    }
    
    func togglePurchasedShoppingListItem(item: ShoppingListItemModel) async throws {
        let context = contextProvider.getContext()
        guard let shoppingItem = try fetchShoppingListItem(id: item.id, context: context) else { throw DBError.unableToGetShoppingItem }
        shoppingItem.purchased.toggle()
        try context.save()
    }
    
    func getGoods(search: String) async throws -> [GoodsItemModel] {
        let context = contextProvider.getContext()
        let search = Self.normalizedName(search)
        let descriptor = FetchDescriptor<Good>(sortBy: [SortDescriptor(\.name)])
        return try context.fetch(descriptor)
            .filter { search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) }
            .map(Self.makeGoodsItemModel)
    }
    
    func addGood(name: String, category: String) async throws -> GoodsItemModel {
        let context = contextProvider.getContext()
        let resolvedName = Self.normalizedName(name)
        let resolvedCategory = Self.normalizedName(category)
        guard !resolvedName.isEmpty else { throw DBError.unableToCreateGood }
        let good = try createOrGetGood(name: resolvedName, context: context)
        if !resolvedCategory.isEmpty {
            good.category = try createOrGetCategory(name: resolvedCategory, context: context)
        }
        try context.save()
        return Self.makeGoodsItemModel(good)
    }
    
    func editGood(item: GoodsItemModel, name: String, category: String) async throws -> GoodsItemModel {
        let context = contextProvider.getContext()
        let resolvedName = Self.normalizedName(name)
        let resolvedCategory = Self.normalizedName(category)
        guard !resolvedName.isEmpty, let good = try fetchGood(id: item.id, context: context) else { throw DBError.unableToGetGood }
        good.name = resolvedName
        good.category = resolvedCategory.isEmpty ? nil : try createOrGetCategory(name: resolvedCategory, context: context)
        try context.save()
        return Self.makeGoodsItemModel(good)
    }
    
    private func createOrGetCategory(name: String, context: ModelContext) throws -> Category {
        let resolvedName = Self.normalizedName(name)
        if let category = try fetchCategory(name: resolvedName, context: context) {
            return category
        }
        let category = Category(name: resolvedName)
        context.insert(category)
        return category
    }
    
    private func fetchCategory(name: String, context: ModelContext) throws -> Category? {
        var descriptor = FetchDescriptor<Category>(predicate: #Predicate { $0.name == name })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
    
    private func fetchCategory(id: String, context: ModelContext) throws -> Category? {
        try fetchModel(id: id, context: context, as: Category.self)
    }
    
    func removeGood(item: GoodsItemModel) async throws {
        let context = contextProvider.getContext()
        guard let good = try fetchGood(id: item.id, context: context) else { throw DBError.unableToGetGood }
        for item in good.items ?? [] {
            item.isRemoved = true
        }
        context.delete(good)
        try context.save()
    }
    
    func getCategories(search: String) async throws -> [CategoriesItemModel] {
        let context = contextProvider.getContext()
        let search = Self.normalizedName(search)
        let descriptor = FetchDescriptor<Category>(sortBy: [SortDescriptor(\.name)])
        return try context.fetch(descriptor)
            .filter { !$0.name.isEmpty && (search.isEmpty || $0.name.localizedCaseInsensitiveContains(search)) }
            .map(Self.makeCategoriesItemModel)
    }
    
    func addCategory(name: String) async throws -> CategoriesItemModel {
        let context = contextProvider.getContext()
        let resolvedName = Self.normalizedName(name)
        guard !resolvedName.isEmpty else { throw DBError.unableToCreateCategory }
        let category = try createOrGetCategory(name: resolvedName, context: context)
        try context.save()
        return Self.makeCategoriesItemModel(category)
    }
    
    func editCategory(item: CategoriesItemModel, name: String) async throws -> CategoriesItemModel {
        let context = contextProvider.getContext()
        let resolvedName = Self.normalizedName(name)
        guard !resolvedName.isEmpty, let category = try fetchCategory(id: item.id, context: context) else { throw DBError.unableToGetCategory }
        category.name = resolvedName
        try context.save()
        return Self.makeCategoriesItemModel(category)
    }
    
    func removeCategory(item: CategoriesItemModel) async throws {
        let context = contextProvider.getContext()
        guard let category = try fetchCategory(id: item.id, context: context) else { throw DBError.unableToGetCategory }
        context.delete(category)
        try context.save()
    }
    
    func getCategoryGoods(item: CategoriesItemModel) async throws -> [GoodsItemModel] {
        let context = contextProvider.getContext()
        guard let category = try fetchCategory(id: item.id, context: context) else { throw DBError.unableToGetCategory }
        return (category.goods ?? [])
            .sorted { $0.name < $1.name }
            .map(Self.makeGoodsItemModel)
    }
    
    func syncCategoryGoods(item: CategoriesItemModel, goods: [String]) async throws {
        let context = contextProvider.getContext()
        guard let category = try fetchCategory(id: item.id, context: context) else { throw DBError.unableToGetCategory }
        let goods = try Self.normalizedNames(goods).map { try createOrGetGood(name: $0, context: context) }
        category.goods = goods
        for good in goods {
            good.category = category
        }
        try context.save()
    }
    
    func getStores(search: String) async throws -> [StoresItemModel] {
        let context = contextProvider.getContext()
        let search = Self.normalizedName(search)
        let descriptor = FetchDescriptor<Store>(sortBy: [SortDescriptor(\.name)])
        return try context.fetch(descriptor)
            .filter { !$0.name.isEmpty && (search.isEmpty || $0.name.localizedCaseInsensitiveContains(search)) }
            .map(Self.makeStoresItemModel)
    }
    
    func addStore(name: String) async throws -> StoresItemModel {
        let context = contextProvider.getContext()
        let resolvedName = Self.normalizedName(name)
        guard !resolvedName.isEmpty else { throw DBError.unableToCreateStore }
        let store = try createOrGetStore(name: resolvedName, context: context)
        try context.save()
        return Self.makeStoresItemModel(store)
    }
    
    func editStore(item: StoresItemModel, name: String) async throws -> StoresItemModel {
        let context = contextProvider.getContext()
        let resolvedName = Self.normalizedName(name)
        guard !resolvedName.isEmpty, let store = try fetchStore(id: item.id, context: context) else { throw DBError.unableToGetStore }
        store.name = resolvedName
        try context.save()
        return Self.makeStoresItemModel(store)
    }
    
    func removeStore(item: StoresItemModel) async throws {
        let context = contextProvider.getContext()
        guard let store = try fetchStore(id: item.id, context: context) else { throw DBError.unableToGetStore }
        context.delete(store)
        try context.save()
    }
    
    func getStoreCategories(item: StoresItemModel) async throws -> [CategoriesItemModel] {
        let context = contextProvider.getContext()
        guard let store = try fetchStore(id: item.id, context: context) else { throw DBError.unableToGetStore }
        return (store.orders ?? [])
            .sorted { $0.order < $1.order }
            .compactMap(\.category)
            .map(Self.makeCategoriesItemModel)
    }
    
    func syncStoreCategories(item: StoresItemModel, categories: [String]) async throws {
        let context = contextProvider.getContext()
        guard let store = try fetchStore(id: item.id, context: context) else { throw DBError.unableToGetStore }
        let categories = try Self.normalizedNames(categories).map { try createOrGetCategory(name: $0, context: context) }
        let existingOrders = store.orders ?? []
        
        for order in existingOrders where !(order.category.map { categories.contains($0) } ?? false) {
            context.delete(order)
        }
        
        let orderedCategories = existingOrders.compactMap(\.category)
        for category in categories where !orderedCategories.contains(category) {
            let order = CategoryStoreOrder(category: category, store: store)
            context.insert(order)
        }
        
        let allOrders = store.orders ?? []
        for (index, category) in categories.enumerated() {
            guard let order = allOrders.first(where: { $0.category == category }) else { throw DBError.unableToGetOrder }
            order.order = index
            order.store = store
            order.category = category
        }
        try context.save()
    }
    
    private static func makeShoppingListModel(_ list: ShoppingList) -> ShoppingListModel {
        ShoppingListModel(id: persistentIDString(list), uniqueId: list.uniqueId, name: list.name, date: list.date)
    }
    
    private static func makeGoodsItemModel(_ good: Good) -> GoodsItemModel {
        GoodsItemModel(id: persistentIDString(good), name: good.name, category: good.category?.name ?? "")
    }
    
    private static func makeCategoriesItemModel(_ category: Category) -> CategoriesItemModel {
        CategoriesItemModel(id: persistentIDString(category), name: category.name)
    }
    
    private static func makeStoresItemModel(_ store: Store) -> StoresItemModel {
        StoresItemModel(id: persistentIDString(store), name: store.name)
    }
}

final class DAOStub: DAOProtocol, @unchecked Sendable {
    var shoppingLists: [ShoppingListModel] = [
        ShoppingListModel(id: UUID().uuidString, uniqueId: "1234124", name: "test1", date: Date()),
        ShoppingListModel(id: UUID().uuidString, uniqueId: "1234125", name: "test2", date: Date()),
        ShoppingListModel(id: UUID().uuidString, uniqueId: "1234126", name: "test3", date: Date()),
        ShoppingListModel(id: UUID().uuidString, uniqueId: "1234127", name: "test4", date: Date()),
        ShoppingListModel(id: UUID().uuidString, uniqueId: "1234128", name: "test5", date: Date()),
        ShoppingListModel(id: UUID().uuidString, uniqueId: "1234129", name: "test6", date: Date()),
        ShoppingListModel(id: UUID().uuidString, uniqueId: "1234120", name: "test7", date: Date())
    ]
    
    func getShoppingLists() async throws -> [ShoppingListModel] { shoppingLists }
    func addShoppingList(name: String, date: Date, uniqueId: String?) async throws -> ShoppingListModel { ShoppingListModel(id: UUID().uuidString, uniqueId: "1241234", name: "test", date: date) }
    func removeShoppingList(_ item: ShoppingListModel) async throws {}
    
    var shoppingItems: [ShoppingListItemModel] = [
        ShoppingListItemModel(id: UUID().uuidString, uniqueId: "1241234", title: "item title1", store: "store1", category: "category1", categoryStoreOrder: 0, isPurchased: false, amount: "15", isWeight: false, price: "15", isImportant: false, rating: 5),
        ShoppingListItemModel(id: UUID().uuidString, uniqueId: "1241235", title: "item title2", store: "store1", category: "category1", categoryStoreOrder: 0, isPurchased: false, amount: "1", isWeight: false, price: "15", isImportant: false, rating: 5),
        ShoppingListItemModel(id: UUID().uuidString, uniqueId: "1241236", title: "item title3", store: "store1", category: "category2", categoryStoreOrder: 0, isPurchased: true, amount: "3", isWeight: false, price: "15", isImportant: false, rating: 5),
        ShoppingListItemModel(id: UUID().uuidString, uniqueId: "1241237", title: "item title4", store: "store1", category: "category2", categoryStoreOrder: 0, isPurchased: false, amount: "2", isWeight: false, price: "15", isImportant: false, rating: 5),
        ShoppingListItemModel(id: UUID().uuidString, uniqueId: "1241238", title: "item title5", store: "store2", category: "category2", categoryStoreOrder: 0, isPurchased: true, amount: "7", isWeight: false, price: "15", isImportant: false, rating: 5),
        ShoppingListItemModel(id: UUID().uuidString, uniqueId: "1241239", title: "item title6", store: "store2", category: "category3", categoryStoreOrder: 0, isPurchased: false, amount: "5", isWeight: false, price: "15", isImportant: false, rating: 5),
        ShoppingListItemModel(id: UUID().uuidString, uniqueId: "1241230", title: "item title7", store: "store2", category: "category3", categoryStoreOrder: 0, isPurchased: false, amount: "20", isWeight: false, price: "15", isImportant: false, rating: 5),
        ShoppingListItemModel(id: UUID().uuidString, uniqueId: "1241231", title: "item title8", store: "store2", category: "category3", categoryStoreOrder: 0, isPurchased: false, amount: "4", isWeight: false, price: "15", isImportant: false, rating: 5),
        ShoppingListItemModel(id: UUID().uuidString, uniqueId: "1241232", title: "item title9", store: "store2", category: "category4", categoryStoreOrder: 0, isPurchased: true, amount: "8", isWeight: false, price: "15", isImportant: false, rating: 5),
        ShoppingListItemModel(id: UUID().uuidString, uniqueId: "1241233", title: "item title10", store: "store2", category: "category4", categoryStoreOrder: 0, isPurchased: false, amount: "24", isWeight: false, price: "15", isImportant: false, rating: 5),
        ShoppingListItemModel(id: UUID().uuidString, uniqueId: "1241214", title: "item title11", store: "store3", category: "category4", categoryStoreOrder: 0, isPurchased: false, amount: "1", isWeight: false, price: "15", isImportant: false, rating: 5),
        ShoppingListItemModel(id: UUID().uuidString, uniqueId: "1241215", title: "item title12", store: "store3", category: "category5", categoryStoreOrder: 0, isPurchased: false, amount: "6", isWeight: false, price: "15", isImportant: false, rating: 5),
        ShoppingListItemModel(id: UUID().uuidString, uniqueId: "1241216", title: "item title13", store: "store3", category: "category5", categoryStoreOrder: 0, isPurchased: false, amount: "18", isWeight: false, price: "15", isImportant: false, rating: 5),
        ShoppingListItemModel(id: UUID().uuidString, uniqueId: "1241217", title: "item title14", store: "store3", category: "category5", categoryStoreOrder: 0, isPurchased: true, amount: "9", isWeight: false, price: "15", isImportant: false, rating: 5),
        ShoppingListItemModel(id: UUID().uuidString, uniqueId: "1241218", title: "item title15", store: "store3", category: "category6", categoryStoreOrder: 0, isPurchased: false, amount: "19", isWeight: false, price: "15", isImportant: false, rating: 5),
        ShoppingListItemModel(id: UUID().uuidString, uniqueId: "1241219", title: "item title16", store: "store3", category: "category6", categoryStoreOrder: 0, isPurchased: false, amount: "10", isWeight: false, price: "15", isImportant: false, rating: 5)
    ]
    
    func getShoppingListItems(list: ShoppingListModel) async throws -> [ShoppingListItemModel] { shoppingItems }
    func addShoppingListItem(list: ShoppingListModel, name: String, amount: String, store: String, isWeight: Bool, price: String, isImportant: Bool, rating: Int, isPurchased: Bool, uniqueId: String?) async throws {}
    func editShoppingListItem(item: ShoppingListItemModel, name: String, amount: String, store: String, isWeight: Bool, price: String, isImportant: Bool, rating: Int) async throws {}
    func removeShoppingListItem(item: ShoppingListItemModel) async throws {}
    func togglePurchasedShoppingListItem(item: ShoppingListItemModel) async throws {}
    
    var goods: [GoodsItemModel] = [
        GoodsItemModel(id: UUID().uuidString, name: "Test good1", category: "Test category1"),
        GoodsItemModel(id: UUID().uuidString, name: "Test good2", category: "Test category1"),
        GoodsItemModel(id: UUID().uuidString, name: "Test good3", category: "Test category1"),
        GoodsItemModel(id: UUID().uuidString, name: "Test good4", category: "Test category2"),
        GoodsItemModel(id: UUID().uuidString, name: "Test good5", category: "Test category2"),
        GoodsItemModel(id: UUID().uuidString, name: "Test good6", category: "Test category2"),
        GoodsItemModel(id: UUID().uuidString, name: "Test good7", category: "Test category3"),
        GoodsItemModel(id: UUID().uuidString, name: "Test good8", category: "Test category3"),
        GoodsItemModel(id: UUID().uuidString, name: "Test good9", category: "Test category3")
    ]
    
    func getGoods(search: String) async throws -> [GoodsItemModel] { search.isEmpty ? goods : goods.filter { $0.name.lowercased().contains(search.lowercased()) } }
    func addGood(name: String, category: String) async throws -> GoodsItemModel { GoodsItemModel(id: UUID().uuidString, name: "Test good", category: "Test category") }
    func editGood(item: GoodsItemModel, name: String, category: String) async throws -> GoodsItemModel { GoodsItemModel(id: UUID().uuidString, name: name, category: category) }
    func removeGood(item: GoodsItemModel) async throws {}
    
    var categories: [CategoriesItemModel] = [
        CategoriesItemModel(id: UUID().uuidString, name: "Test category 1"),
        CategoriesItemModel(id: UUID().uuidString, name: "Test category 2"),
        CategoriesItemModel(id: UUID().uuidString, name: "Test category 3"),
        CategoriesItemModel(id: UUID().uuidString, name: "Test category 4")
    ]
    
    func getCategories(search: String) async throws -> [CategoriesItemModel] { search.isEmpty ? categories : categories.filter { $0.name.lowercased().contains(search.lowercased()) } }
    func addCategory(name: String) async throws -> CategoriesItemModel { CategoriesItemModel(id: UUID().uuidString, name: "Test category") }
    func editCategory(item: CategoriesItemModel, name: String) async throws -> CategoriesItemModel { CategoriesItemModel(id: UUID().uuidString, name: name) }
    func removeCategory(item: CategoriesItemModel) async throws {}
    func getCategoryGoods(item: CategoriesItemModel) async throws -> [GoodsItemModel] { [] }
    func syncCategoryGoods(item: CategoriesItemModel, goods: [String]) async throws {}
    
    var stores: [StoresItemModel] = [
        StoresItemModel(id: UUID().uuidString, name: "Test store 1"),
        StoresItemModel(id: UUID().uuidString, name: "Test store 2"),
        StoresItemModel(id: UUID().uuidString, name: "Test store 3"),
        StoresItemModel(id: UUID().uuidString, name: "Test store 4"),
        StoresItemModel(id: UUID().uuidString, name: "Test store 5"),
        StoresItemModel(id: UUID().uuidString, name: "Test store 6"),
        StoresItemModel(id: UUID().uuidString, name: "Test store 7"),
        StoresItemModel(id: UUID().uuidString, name: "Test store 8")
    ]
    
    func getStores(search: String) async throws -> [StoresItemModel] { search.isEmpty ? stores : stores.filter { $0.name.lowercased().contains(search.lowercased()) } }
    func addStore(name: String) async throws -> StoresItemModel { StoresItemModel(id: UUID().uuidString, name: "Test store") }
    func editStore(item: StoresItemModel, name: String) async throws -> StoresItemModel { StoresItemModel(id: UUID().uuidString, name: name) }
    func removeStore(item: StoresItemModel) async throws {}
    func getStoreCategories(item: StoresItemModel) async throws -> [CategoriesItemModel] { [] }
    func syncStoreCategories(item: StoresItemModel, categories: [String]) async throws {}
}
