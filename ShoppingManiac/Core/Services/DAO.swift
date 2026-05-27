//
//  DAO.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 10.10.2021.
//

import FactoryKit
import Foundation
import SwiftData

struct ShoppingListImportItem: Sendable, Equatable {
    let name: String
    let amount: Decimal
    let store: String
    let isWeight: Bool
    let price: Decimal
    let isImportant: Bool
    let isPurchased: Bool
}

struct ShoppingListImport: Sendable, Equatable {
    let name: String
    let date: Date
    let items: [ShoppingListImportItem]
}

@MainActor
protocol DAOProtocol {
    func getShoppingLists() async throws -> [ShoppingListModel]
    func addShoppingList(name: String, date: Date) async throws -> ShoppingListModel
    func importShoppingList(name: String, date: Date, items: [ShoppingListImportItem]) async throws -> ShoppingListModel
    func importShoppingLists(_ lists: [ShoppingListImport]) async throws -> [ShoppingListModel]
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
                             isPurchased: Bool) async throws
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
    func getGoods(search: String, limit: Int?) async throws -> [GoodsItemModel]
    func addGood(name: String, category: String) async throws -> GoodsItemModel
    func editGood(item: GoodsItemModel, name: String, category: String) async throws -> GoodsItemModel
    func removeGood(item: GoodsItemModel) async throws
    func getCategories(search: String, limit: Int?) async throws -> [CategoriesItemModel]
    func addCategory(name: String) async throws -> CategoriesItemModel
    func editCategory(item: CategoriesItemModel, name: String) async throws -> CategoriesItemModel
    func saveCategory(item: CategoriesItemModel?, name: String, goods: [String]) async throws -> CategoriesItemModel
    func removeCategory(item: CategoriesItemModel) async throws
    func getCategoryGoods(item: CategoriesItemModel) async throws -> [GoodsItemModel]
    func syncCategoryGoods(item: CategoriesItemModel, goods: [String]) async throws
    func getStores(search: String, limit: Int?) async throws -> [StoresItemModel]
    func addStore(name: String) async throws -> StoresItemModel
    func editStore(item: StoresItemModel, name: String) async throws -> StoresItemModel
    func saveStore(item: StoresItemModel?, name: String, categories: [String]) async throws -> StoresItemModel
    func removeStore(item: StoresItemModel) async throws
    func getStoreCategories(item: StoresItemModel) async throws -> [CategoriesItemModel]
    func syncStoreCategories(item: StoresItemModel, categories: [String]) async throws
}

extension DAOProtocol {
    func getGoods(search: String) async throws -> [GoodsItemModel] {
        try await getGoods(search: search, limit: nil)
    }

    func getCategories(search: String) async throws -> [CategoriesItemModel] {
        try await getCategories(search: search, limit: nil)
    }

    func getStores(search: String) async throws -> [StoresItemModel] {
        try await getStores(search: search, limit: nil)
    }
}

@MainActor
final class DAO: DAOProtocol {
    enum DBError: Error, Equatable, LocalizedError {
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
        case unableToCreateOrder
        case unableToGetOrder
        case invalidShoppingItemName

        var errorDescription: String? {
            switch self {
            case .unableToCreateShoppingList:
                "Unable to create shopping list."
            case .unableToGetShoppingList:
                "Unable to load shopping list."
            case .unableToCreateShoppingItem:
                "Unable to create shopping item."
            case .unableToGetShoppingItem:
                "Unable to load shopping item."
            case .unableToCreateGood:
                "Unable to create good."
            case .unableToGetGood:
                "Unable to load good."
            case .unableToCreateCategory:
                "Unable to create category."
            case .unableToGetCategory:
                "Unable to load category."
            case .unableToCreateStore:
                "Unable to create store."
            case .unableToGetStore:
                "Unable to load store."
            case .unableToCreateOrder:
                "Unable to create category order."
            case .unableToGetOrder:
                "Unable to load category order."
            case .invalidShoppingItemName:
                "Shopping item name cannot be empty."
            }
        }
    }

    @Injected(\.contextProvider) private var contextProvider: ContextProviderProtocol

    nonisolated required init() {}

    private static func normalizedName(_ name: String) -> String {
        name.shoppingNormalizedName
    }

    private static func canonicalName(_ name: String) -> String {
        name.shoppingCanonicalName
    }

    private static func normalizedNames(_ names: [String]) -> [String] {
        var seenNames = Set<String>()
        return names
            .map(normalizedName)
            .filter { !$0.isEmpty }
            .filter { seenNames.insert(canonicalName($0)).inserted }
    }

    static func persistentIDString<T: PersistentModel>(_ model: T) -> String {
        guard let data = try? JSONEncoder().encode(model.persistentModelID) else {
            return String(describing: model.persistentModelID.id)
        }
        return data.base64EncodedString()
    }

    private static func persistentID(from string: String) -> PersistentIdentifier? {
        guard let data = Data(base64Encoded: string) else { return nil }
        return try? JSONDecoder().decode(PersistentIdentifier.self, from: data)
    }

    private func fetchModel<T: PersistentModel>(id: String, context: ModelContext, as type: T.Type) throws -> T? {
        if let persistentID = Self.persistentID(from: id),
           let model = context.model(for: persistentID) as? T {
            return model
        }
        let descriptor = FetchDescriptor<T>()
        return try context.fetch(descriptor).first { Self.persistentIDString($0) == id }
    }

    private static func decimal(from string: String, default defaultValue: Decimal) -> Decimal {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.number(from: normalizedName(string))?.decimalValue ?? defaultValue
    }

    private static func decimalString(_ value: Decimal, maximumFractionDigits: Int? = nil) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        if let maximumFractionDigits {
            formatter.maximumFractionDigits = maximumFractionDigits
        }
        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? ""
    }

    func getShoppingLists() async throws -> [ShoppingListModel] {
        let context = contextProvider.getContext()
        let descriptor = FetchDescriptor<ShoppingList>(
            predicate: #Predicate { !$0.isRemoved },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try context.fetch(descriptor).map(Self.makeShoppingListModel)
    }

    func addShoppingList(name: String, date: Date) async throws -> ShoppingListModel {
        let context = contextProvider.getContext()
        let item = ShoppingList()
        context.insert(item)
        item.name = Self.normalizedName(name)
        item.date = date
        item.isRemoved = false
        try context.save()
        return Self.makeShoppingListModel(item)
    }

    func importShoppingList(name: String, date: Date, items: [ShoppingListImportItem]) async throws -> ShoppingListModel {
        guard let list = try await importShoppingLists([ShoppingListImport(name: name, date: date, items: items)]).first else {
            throw DBError.unableToCreateShoppingList
        }
        return list
    }

    func importShoppingLists(_ lists: [ShoppingListImport]) async throws -> [ShoppingListModel] {
        let context = contextProvider.getContext()
        var importedLists: [ShoppingList] = []
        importedLists.reserveCapacity(lists.count)

        for importedList in lists {
            let list = ShoppingList()
            context.insert(list)
            list.name = Self.normalizedName(importedList.name)
            list.date = importedList.date
            list.isRemoved = false

            for importedItem in importedList.items {
                let item = ShoppingListItem()
                context.insert(item)
                try configureShoppingListItem(
                    item,
                    list: list,
                    name: importedItem.name,
                    amount: importedItem.amount,
                    store: importedItem.store,
                    isWeight: importedItem.isWeight,
                    price: importedItem.price,
                    isImportant: importedItem.isImportant,
                    rating: 0,
                    isPurchased: importedItem.isPurchased,
                    context: context
                )
            }

            importedLists.append(list)
        }

        try context.save()
        return importedLists.map(Self.makeShoppingListModel)
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
        let descriptor = FetchDescriptor<ShoppingListItem>(
            predicate: #Predicate { !$0.isRemoved && $0.list?.persistentModelID == listPersistentID }
        )
        return try context.fetch(descriptor).map(Self.makeShoppingListItemModel)
    }

    func addShoppingListItem(list: ShoppingListModel,
                             name: String,
                             amount: String,
                             store: String,
                             isWeight: Bool,
                             price: String,
                             isImportant: Bool,
                             rating: Int,
                             isPurchased: Bool) async throws {
        let context = contextProvider.getContext()
        guard let shoppingList = try fetchShoppingList(id: list.id, context: context) else { throw DBError.unableToGetShoppingList }
        let item = ShoppingListItem()
        context.insert(item)
        try configureShoppingListItem(
            item,
            list: shoppingList,
            name: name,
            amount: Self.decimal(from: amount, default: 1),
            store: store,
            isWeight: isWeight,
            price: Self.decimal(from: price, default: 0),
            isImportant: isImportant,
            rating: rating,
            isPurchased: isPurchased,
            context: context
        )
        try context.save()
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
        guard let shoppingItem = try fetchShoppingListItem(id: item.id, context: context) else { throw DBError.unableToGetShoppingItem }
        try configureShoppingListItem(
            shoppingItem,
            list: shoppingItem.list,
            name: name,
            amount: Self.decimal(from: amount, default: 1),
            store: store,
            isWeight: isWeight,
            price: Self.decimal(from: price, default: 0),
            isImportant: isImportant,
            rating: rating,
            isPurchased: shoppingItem.purchased,
            context: context
        )
        try context.save()
    }

    private func configureShoppingListItem(_ item: ShoppingListItem,
                                           list: ShoppingList?,
                                           name: String,
                                           amount: Decimal,
                                           store: String,
                                           isWeight: Bool,
                                           price: Decimal,
                                           isImportant: Bool,
                                           rating: Int,
                                           isPurchased: Bool,
                                           context: ModelContext) throws {
        let resolvedName = Self.normalizedName(name)
        let resolvedStore = Self.normalizedName(store)
        guard !resolvedName.isEmpty else { throw DBError.invalidShoppingItemName }
        item.list = list
        item.good = try createOrGetGood(name: resolvedName, context: context)
        item.quantity = amount
        item.rating = rating
        item.isWeight = isWeight
        item.price = price
        item.isImportant = isImportant
        item.purchased = isPurchased
        item.isRemoved = false
        item.store = resolvedStore.isEmpty ? nil : try createOrGetStore(name: resolvedStore, context: context)
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

    func getGoods(search: String, limit: Int? = nil) async throws -> [GoodsItemModel] {
        let context = contextProvider.getContext()
        let search = Self.canonicalName(search)
        var descriptor = search.isEmpty
            ? FetchDescriptor<Good>(predicate: #Predicate { !$0.isRemoved }, sortBy: [SortDescriptor(\.name)])
            : FetchDescriptor<Good>(predicate: #Predicate { !$0.isRemoved && $0.canonicalName.contains(search) }, sortBy: [SortDescriptor(\.name)])
        if let limit {
            descriptor.fetchLimit = limit
        }
        return try context.fetch(descriptor).map(Self.makeGoodsItemModel)
    }

    func addGood(name: String, category: String) async throws -> GoodsItemModel {
        let context = contextProvider.getContext()
        let resolvedName = Self.normalizedName(name)
        let resolvedCategory = Self.normalizedName(category)
        guard !resolvedName.isEmpty else { throw DBError.unableToCreateGood }
        let good = try createOrGetGood(name: resolvedName, context: context)
        good.category = resolvedCategory.isEmpty ? nil : try createOrGetCategory(name: resolvedCategory, context: context)
        good.isRemoved = false
        try context.save()
        return Self.makeGoodsItemModel(good)
    }

    func editGood(item: GoodsItemModel, name: String, category: String) async throws -> GoodsItemModel {
        let context = contextProvider.getContext()
        let resolvedName = Self.normalizedName(name)
        let resolvedCategory = Self.normalizedName(category)
        guard !resolvedName.isEmpty, let good = try fetchGood(id: item.id, context: context) else { throw DBError.unableToGetGood }
        good.name = resolvedName
        good.canonicalName = Self.canonicalName(resolvedName)
        good.isRemoved = false
        good.category = resolvedCategory.isEmpty ? nil : try createOrGetCategory(name: resolvedCategory, context: context)
        try context.save()
        return Self.makeGoodsItemModel(good)
    }

    private func createOrGetGood(name: String, context: ModelContext) throws -> Good {
        let resolvedName = Self.normalizedName(name)
        let canonicalName = Self.canonicalName(resolvedName)
        if let good = try fetchGood(canonicalName: canonicalName, context: context) {
            good.name = resolvedName
            good.canonicalName = canonicalName
            good.isRemoved = false
            return good
        }
        let good = Good(name: resolvedName)
        good.canonicalName = canonicalName
        context.insert(good)
        return good
    }

    private func fetchGood(canonicalName: String, context: ModelContext) throws -> Good? {
        var descriptor = FetchDescriptor<Good>(predicate: #Predicate { $0.canonicalName == canonicalName })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func fetchGood(id: String, context: ModelContext) throws -> Good? {
        try fetchModel(id: id, context: context, as: Good.self)
    }

    func removeGood(item: GoodsItemModel) async throws {
        let context = contextProvider.getContext()
        guard let good = try fetchGood(id: item.id, context: context) else { throw DBError.unableToGetGood }
        good.isRemoved = true
        try context.save()
    }

    func getCategories(search: String, limit: Int? = nil) async throws -> [CategoriesItemModel] {
        let context = contextProvider.getContext()
        let search = Self.canonicalName(search)
        var descriptor = search.isEmpty
            ? FetchDescriptor<Category>(predicate: #Predicate { !$0.isRemoved && !$0.name.isEmpty }, sortBy: [SortDescriptor(\.name)])
            : FetchDescriptor<Category>(predicate: #Predicate { !$0.isRemoved && !$0.name.isEmpty && $0.canonicalName.contains(search) }, sortBy: [SortDescriptor(\.name)])
        if let limit {
            descriptor.fetchLimit = limit
        }
        return try context.fetch(descriptor).map(Self.makeCategoriesItemModel)
    }

    func addCategory(name: String) async throws -> CategoriesItemModel {
        let context = contextProvider.getContext()
        let resolvedName = Self.normalizedName(name)
        guard !resolvedName.isEmpty else { throw DBError.unableToCreateCategory }
        let category = try createOrGetCategory(name: resolvedName, context: context)
        category.isRemoved = false
        try context.save()
        return Self.makeCategoriesItemModel(category)
    }

    func editCategory(item: CategoriesItemModel, name: String) async throws -> CategoriesItemModel {
        let context = contextProvider.getContext()
        let category = try updateCategory(item: item, name: name, context: context)
        try context.save()
        return Self.makeCategoriesItemModel(category)
    }

    func saveCategory(item: CategoriesItemModel?, name: String, goods: [String]) async throws -> CategoriesItemModel {
        let context = contextProvider.getContext()
        let category: Category
        if let item {
            category = try updateCategory(item: item, name: name, context: context)
        } else {
            let resolvedName = Self.normalizedName(name)
            guard !resolvedName.isEmpty else { throw DBError.unableToCreateCategory }
            category = try createOrGetCategory(name: resolvedName, context: context)
        }
        try syncCategoryGoods(category: category, goods: goods, context: context)
        try context.save()
        return Self.makeCategoriesItemModel(category)
    }

    private func updateCategory(item: CategoriesItemModel, name: String, context: ModelContext) throws -> Category {
        let resolvedName = Self.normalizedName(name)
        guard !resolvedName.isEmpty, let category = try fetchCategory(id: item.id, context: context) else { throw DBError.unableToGetCategory }
        category.name = resolvedName
        category.canonicalName = Self.canonicalName(resolvedName)
        category.isRemoved = false
        return category
    }

    private func createOrGetCategory(name: String, context: ModelContext) throws -> Category {
        let resolvedName = Self.normalizedName(name)
        let canonicalName = Self.canonicalName(resolvedName)
        if let category = try fetchCategory(canonicalName: canonicalName, context: context) {
            category.name = resolvedName
            category.canonicalName = canonicalName
            category.isRemoved = false
            return category
        }
        let category = Category(name: resolvedName)
        category.canonicalName = canonicalName
        context.insert(category)
        return category
    }

    private func fetchCategory(canonicalName: String, context: ModelContext) throws -> Category? {
        var descriptor = FetchDescriptor<Category>(predicate: #Predicate { $0.canonicalName == canonicalName })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func fetchCategory(id: String, context: ModelContext) throws -> Category? {
        try fetchModel(id: id, context: context, as: Category.self)
    }

    func removeCategory(item: CategoriesItemModel) async throws {
        let context = contextProvider.getContext()
        guard let category = try fetchCategory(id: item.id, context: context) else { throw DBError.unableToGetCategory }
        category.isRemoved = true
        try context.save()
    }

    func getCategoryGoods(item: CategoriesItemModel) async throws -> [GoodsItemModel] {
        let context = contextProvider.getContext()
        guard let category = try fetchCategory(id: item.id, context: context) else { throw DBError.unableToGetCategory }
        return (category.goods ?? [])
            .filter { !$0.isRemoved }
            .sorted { $0.name < $1.name }
            .map(Self.makeGoodsItemModel)
    }

    func syncCategoryGoods(item: CategoriesItemModel, goods: [String]) async throws {
        let context = contextProvider.getContext()
        guard let category = try fetchCategory(id: item.id, context: context) else { throw DBError.unableToGetCategory }
        try syncCategoryGoods(category: category, goods: goods, context: context)
        try context.save()
    }

    private func syncCategoryGoods(category: Category, goods: [String], context: ModelContext) throws {
        let goods = try Self.normalizedNames(goods).map { try createOrGetGood(name: $0, context: context) }
        for existingGood in category.goods ?? [] where goods.contains(existingGood) == false {
            existingGood.category = nil
        }
        category.goods = goods
        for good in goods {
            good.category = category
        }
    }

    func getStores(search: String, limit: Int? = nil) async throws -> [StoresItemModel] {
        let context = contextProvider.getContext()
        let search = Self.canonicalName(search)
        var descriptor = search.isEmpty
            ? FetchDescriptor<Store>(predicate: #Predicate { !$0.isRemoved && !$0.name.isEmpty }, sortBy: [SortDescriptor(\.name)])
            : FetchDescriptor<Store>(predicate: #Predicate { !$0.isRemoved && !$0.name.isEmpty && $0.canonicalName.contains(search) }, sortBy: [SortDescriptor(\.name)])
        if let limit {
            descriptor.fetchLimit = limit
        }
        return try context.fetch(descriptor).map(Self.makeStoresItemModel)
    }

    func addStore(name: String) async throws -> StoresItemModel {
        let context = contextProvider.getContext()
        let resolvedName = Self.normalizedName(name)
        guard !resolvedName.isEmpty else { throw DBError.unableToCreateStore }
        let store = try createOrGetStore(name: resolvedName, context: context)
        store.isRemoved = false
        try context.save()
        return Self.makeStoresItemModel(store)
    }

    func editStore(item: StoresItemModel, name: String) async throws -> StoresItemModel {
        let context = contextProvider.getContext()
        let store = try updateStore(item: item, name: name, context: context)
        try context.save()
        return Self.makeStoresItemModel(store)
    }

    func saveStore(item: StoresItemModel?, name: String, categories: [String]) async throws -> StoresItemModel {
        let context = contextProvider.getContext()
        let store: Store
        if let item {
            store = try updateStore(item: item, name: name, context: context)
        } else {
            let resolvedName = Self.normalizedName(name)
            guard !resolvedName.isEmpty else { throw DBError.unableToCreateStore }
            store = try createOrGetStore(name: resolvedName, context: context)
        }
        try syncStoreCategories(store: store, categories: categories, context: context)
        try context.save()
        return Self.makeStoresItemModel(store)
    }

    private func updateStore(item: StoresItemModel, name: String, context: ModelContext) throws -> Store {
        let resolvedName = Self.normalizedName(name)
        guard !resolvedName.isEmpty, let store = try fetchStore(id: item.id, context: context) else { throw DBError.unableToGetStore }
        store.name = resolvedName
        store.canonicalName = Self.canonicalName(resolvedName)
        store.isRemoved = false
        return store
    }

    private func createOrGetStore(name: String, context: ModelContext) throws -> Store {
        let resolvedName = Self.normalizedName(name)
        let canonicalName = Self.canonicalName(resolvedName)
        if let store = try fetchStore(canonicalName: canonicalName, context: context) {
            store.name = resolvedName
            store.canonicalName = canonicalName
            store.isRemoved = false
            return store
        }
        let store = Store(name: resolvedName)
        store.canonicalName = canonicalName
        context.insert(store)
        return store
    }

    private func fetchStore(canonicalName: String, context: ModelContext) throws -> Store? {
        var descriptor = FetchDescriptor<Store>(predicate: #Predicate { $0.canonicalName == canonicalName })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func fetchStore(id: String, context: ModelContext) throws -> Store? {
        try fetchModel(id: id, context: context, as: Store.self)
    }

    func removeStore(item: StoresItemModel) async throws {
        let context = contextProvider.getContext()
        guard let store = try fetchStore(id: item.id, context: context) else { throw DBError.unableToGetStore }
        store.isRemoved = true
        try context.save()
    }

    func getStoreCategories(item: StoresItemModel) async throws -> [CategoriesItemModel] {
        let context = contextProvider.getContext()
        guard let store = try fetchStore(id: item.id, context: context) else { throw DBError.unableToGetStore }
        return (store.orders ?? [])
            .sorted { $0.order < $1.order }
            .compactMap(\.category)
            .filter { !$0.isRemoved }
            .map(Self.makeCategoriesItemModel)
    }

    func syncStoreCategories(item: StoresItemModel, categories: [String]) async throws {
        let context = contextProvider.getContext()
        guard let store = try fetchStore(id: item.id, context: context) else { throw DBError.unableToGetStore }
        try syncStoreCategories(store: store, categories: categories, context: context)
        try context.save()
    }

    private func syncStoreCategories(store: Store, categories: [String], context: ModelContext) throws {
        let categories = try Self.normalizedNames(categories).map { try createOrGetCategory(name: $0, context: context) }
        var orders = store.orders ?? []

        for order in orders where order.category.map({ categories.contains($0) }) != true {
            context.delete(order)
        }
        orders.removeAll { order in
            order.category.map { categories.contains($0) } != true
        }

        for category in categories where orders.contains(where: { $0.category == category }) == false {
            let order = CategoryStoreOrder(category: category, store: store)
            context.insert(order)
            orders.append(order)
        }

        for (index, category) in categories.enumerated() {
            guard let order = orders.first(where: { $0.category == category }) else { throw DBError.unableToGetOrder }
            order.order = index
            order.store = store
            order.category = category
        }
    }

    private static func makeShoppingListModel(_ list: ShoppingList) -> ShoppingListModel {
        ShoppingListModel(id: persistentIDString(list), name: list.name, date: list.date)
    }

    private static func makeShoppingListItemModel(_ item: ShoppingListItem) -> ShoppingListItemModel {
        let orders = item.good?.category?.orders ?? []
        let order = orders.first(where: { $0.store?.persistentModelID == item.store?.persistentModelID })?.order
        let amount = decimalString(item.quantity, maximumFractionDigits: item.isWeight ? 2 : 0)
        let price = decimalString(item.price, maximumFractionDigits: 2)
        let id = persistentIDString(item)
        return ShoppingListItemModel(id: id,
                                     title: item.good?.name ?? "",
                                     store: item.store?.name ?? "",
                                     category: item.good?.category?.name ?? "",
                                     categoryStoreOrder: order,
                                     isPurchased: item.purchased,
                                     amount: amount,
                                     isWeight: item.isWeight,
                                     price: price,
                                     isImportant: item.isImportant,
                                     rating: item.rating)
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
