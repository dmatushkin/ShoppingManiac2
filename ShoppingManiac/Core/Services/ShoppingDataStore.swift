//
//  ShoppingDataStore.swift
//  ShoppingManiac2
//
//  Created by Codex on 10.06.2026.
//

import Foundation
import SwiftData

@ModelActor
actor ShoppingDataStore {
    static func persistentIDString<T: PersistentModel>(_ model: T) -> String {
        guard let data = try? JSONEncoder().encode(model.persistentModelID) else {
            return String(describing: model.persistentModelID.id)
        }
        return data.base64EncodedString()
    }

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

    private static func persistentID(from string: String) -> PersistentIdentifier? {
        guard let data = Data(base64Encoded: string) else { return nil }
        return try? JSONDecoder().decode(PersistentIdentifier.self, from: data)
    }

    private func fetchModel<T: PersistentModel>(id: String, as type: T.Type) throws -> T? {
        if let persistentID = Self.persistentID(from: id),
           let model = modelContext.model(for: persistentID) as? T {
            return model
        }
        let descriptor = FetchDescriptor<T>()
        return try modelContext.fetch(descriptor).first { Self.persistentIDString($0) == id }
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

    func getShoppingLists() throws -> [ShoppingListModel] {
        let descriptor = FetchDescriptor<ShoppingList>(
            predicate: #Predicate { !$0.isRemoved },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map(Self.makeShoppingListModel)
    }

    func addShoppingList(name: String, date: Date) throws -> ShoppingListModel {
        do {
            let item = ShoppingList()
            modelContext.insert(item)
            item.name = Self.normalizedName(name)
            item.date = date
            item.isRemoved = false
            try modelContext.save()
            return Self.makeShoppingListModel(item)
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    func importShoppingList(name: String, date: Date, items: [ShoppingListImportItem]) throws -> ShoppingListModel {
        guard let list = try importShoppingLists([ShoppingListImport(name: name, date: date, items: items)]).first else {
            throw DAO.DBError.unableToCreateShoppingList
        }
        return list
    }

    func importShoppingLists(_ lists: [ShoppingListImport]) throws -> [ShoppingListModel] {
        do {
            let allGoodsNames = lists.flatMap { list in
                list.items.map(\.name)
            }
            let allStoreNames = lists.flatMap { list in
                list.items.map(\.store)
            }
            let goodsByCanonicalName = try resolveGoodsByCanonicalName(names: allGoodsNames)
            let storesByCanonicalName = try resolveStoresByCanonicalName(names: allStoreNames)
            var importedLists: [ShoppingList] = []
            importedLists.reserveCapacity(lists.count)

            for importedList in lists {
                let list = ShoppingList()
                modelContext.insert(list)
                list.name = Self.normalizedName(importedList.name)
                list.date = importedList.date
                list.isRemoved = false

                for importedItem in importedList.items {
                    let item = ShoppingListItem()
                    modelContext.insert(item)
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
                        goodsByCanonicalName: goodsByCanonicalName,
                        storesByCanonicalName: storesByCanonicalName
                    )
                }

                importedLists.append(list)
            }

            try modelContext.save()
            return importedLists.map(Self.makeShoppingListModel)
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    private func fetchShoppingList(id: String) throws -> ShoppingList? {
        try fetchModel(id: id, as: ShoppingList.self)
    }

    func removeShoppingList(_ item: ShoppingListModel) throws {
        do {
            guard let item = try fetchShoppingList(id: item.id) else { throw DAO.DBError.unableToGetShoppingList }
            item.isRemoved = true
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    func getShoppingListItems(list: ShoppingListModel) throws -> [ShoppingListItemModel] {
        guard let list = try fetchShoppingList(id: list.id) else { throw DAO.DBError.unableToGetShoppingList }
        let listPersistentID = list.persistentModelID
        let descriptor = FetchDescriptor<ShoppingListItem>(
            predicate: #Predicate { !$0.isRemoved && $0.list?.persistentModelID == listPersistentID }
        )
        return try modelContext.fetch(descriptor).map(Self.makeShoppingListItemModel)
    }

    func addShoppingListItem(list: ShoppingListModel,
                             name: String,
                             amount: String,
                             store: String,
                             isWeight: Bool,
                             price: String,
                             isImportant: Bool,
                             rating: Int,
                             isPurchased: Bool) throws {
        do {
            guard let shoppingList = try fetchShoppingList(id: list.id) else { throw DAO.DBError.unableToGetShoppingList }
            let item = ShoppingListItem()
            modelContext.insert(item)
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
                isPurchased: isPurchased
            )
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    private func fetchShoppingListItem(id: String) throws -> ShoppingListItem? {
        try fetchModel(id: id, as: ShoppingListItem.self)
    }

    func editShoppingListItem(item: ShoppingListItemModel,
                              name: String,
                              amount: String,
                              store: String,
                              isWeight: Bool,
                              price: String,
                              isImportant: Bool,
                              rating: Int) throws {
        do {
            guard let shoppingItem = try fetchShoppingListItem(id: item.id) else { throw DAO.DBError.unableToGetShoppingItem }
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
                isPurchased: shoppingItem.purchased
            )
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
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
                                           goodsByCanonicalName: [String: Good]? = nil,
                                           storesByCanonicalName: [String: Store]? = nil) throws {
        let resolvedName = Self.normalizedName(name)
        let resolvedStore = Self.normalizedName(store)
        guard !resolvedName.isEmpty else { throw DAO.DBError.invalidShoppingItemName }
        item.list = list
        item.good = try resolveGood(
            name: resolvedName,
            goodsByCanonicalName: goodsByCanonicalName
        )
        item.quantity = amount
        item.rating = rating
        item.isWeight = isWeight
        item.price = price
        item.isImportant = isImportant
        item.purchased = isPurchased
        item.isRemoved = false
        item.store = resolvedStore.isEmpty ? nil : try resolveStore(
            name: resolvedStore,
            storesByCanonicalName: storesByCanonicalName
        )
    }

    func removeShoppingListItem(item: ShoppingListItemModel) throws {
        do {
            guard let shoppingItem = try fetchShoppingListItem(id: item.id) else { throw DAO.DBError.unableToGetShoppingItem }
            shoppingItem.isRemoved = true
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    func togglePurchasedShoppingListItem(item: ShoppingListItemModel) throws {
        do {
            guard let shoppingItem = try fetchShoppingListItem(id: item.id) else { throw DAO.DBError.unableToGetShoppingItem }
            shoppingItem.purchased.toggle()
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    func getGoods(search: String, limit: Int? = nil) throws -> [GoodsItemModel] {
        let search = Self.canonicalName(search)
        var descriptor = search.isEmpty
            ? FetchDescriptor<Good>(predicate: #Predicate { !$0.isRemoved }, sortBy: [SortDescriptor(\.name)])
            : FetchDescriptor<Good>(predicate: #Predicate { !$0.isRemoved && $0.canonicalName.contains(search) }, sortBy: [SortDescriptor(\.name)])
        if let limit {
            descriptor.fetchLimit = limit
        }
        return try modelContext.fetch(descriptor).map(Self.makeGoodsItemModel)
    }

    func addGood(name: String, category: String) throws -> GoodsItemModel {
        do {
            let resolvedName = Self.normalizedName(name)
            let resolvedCategory = Self.normalizedName(category)
            guard !resolvedName.isEmpty else { throw DAO.DBError.unableToCreateGood }
            let good = try resolveGood(name: resolvedName)
            good.category = resolvedCategory.isEmpty ? nil : try resolveCategory(name: resolvedCategory)
            good.isRemoved = false
            try modelContext.save()
            return Self.makeGoodsItemModel(good)
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    func editGood(item: GoodsItemModel, name: String, category: String) throws -> GoodsItemModel {
        do {
            let resolvedName = Self.normalizedName(name)
            let resolvedCategory = Self.normalizedName(category)
            guard !resolvedName.isEmpty, let good = try fetchGood(id: item.id) else { throw DAO.DBError.unableToGetGood }
            good.name = resolvedName
            good.canonicalName = Self.canonicalName(resolvedName)
            good.isRemoved = false
            good.category = resolvedCategory.isEmpty ? nil : try resolveCategory(name: resolvedCategory)
            try modelContext.save()
            return Self.makeGoodsItemModel(good)
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    private func resolveGood(name: String, goodsByCanonicalName: [String: Good]? = nil) throws -> Good {
        let resolvedName = Self.normalizedName(name)
        let canonicalName = Self.canonicalName(resolvedName)
        if let good = goodsByCanonicalName?[canonicalName] {
            good.name = resolvedName
            good.canonicalName = canonicalName
            good.isRemoved = false
            return good
        }
        if let good = try fetchGood(canonicalName: canonicalName) {
            good.name = resolvedName
            good.canonicalName = canonicalName
            good.isRemoved = false
            return good
        }
        let good = Good(name: resolvedName)
        good.canonicalName = canonicalName
        modelContext.insert(good)
        return good
    }

    private func resolveGoods(names: [String]) throws -> [Good] {
        let goodsByCanonicalName = try resolveGoodsByCanonicalName(names: names)
        return Self.normalizedNames(names).compactMap { name in
            goodsByCanonicalName[Self.canonicalName(name)]
        }
    }

    private func resolveGoodsByCanonicalName(names: [String]) throws -> [String: Good] {
        let normalizedNames = Self.normalizedNames(names)
        let canonicalNames = Set(normalizedNames.map(Self.canonicalName))
        var goodsByCanonicalName = try fetchGoods(canonicalNames: canonicalNames)

        for name in normalizedNames {
            let canonicalName = Self.canonicalName(name)
            if let good = goodsByCanonicalName[canonicalName] {
                good.name = name
                good.canonicalName = canonicalName
                good.isRemoved = false
            } else {
                let good = Good(name: name)
                good.canonicalName = canonicalName
                modelContext.insert(good)
                goodsByCanonicalName[canonicalName] = good
            }
        }

        return goodsByCanonicalName
    }

    private func fetchGoods(canonicalNames: Set<String>) throws -> [String: Good] {
        guard !canonicalNames.isEmpty else { return [:] }
        let canonicalNames = Array(canonicalNames)
        let descriptor = FetchDescriptor<Good>(
            predicate: #Predicate { canonicalNames.contains($0.canonicalName) }
        )
        return try modelContext.fetch(descriptor).reduce(into: [:]) { result, good in
            result[good.canonicalName, default: good] = good
        }
    }

    private func fetchGood(canonicalName: String) throws -> Good? {
        var descriptor = FetchDescriptor<Good>(predicate: #Predicate { $0.canonicalName == canonicalName })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func fetchGood(id: String) throws -> Good? {
        try fetchModel(id: id, as: Good.self)
    }

    func removeGood(item: GoodsItemModel) throws {
        do {
            guard let good = try fetchGood(id: item.id) else { throw DAO.DBError.unableToGetGood }
            good.isRemoved = true
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    func getCategories(search: String, limit: Int? = nil) throws -> [CategoriesItemModel] {
        let search = Self.canonicalName(search)
        var descriptor = search.isEmpty
            ? FetchDescriptor<Category>(predicate: #Predicate { !$0.isRemoved && !$0.name.isEmpty }, sortBy: [SortDescriptor(\.name)])
            : FetchDescriptor<Category>(predicate: #Predicate { !$0.isRemoved && !$0.name.isEmpty && $0.canonicalName.contains(search) }, sortBy: [SortDescriptor(\.name)])
        if let limit {
            descriptor.fetchLimit = limit
        }
        return try modelContext.fetch(descriptor).map(Self.makeCategoriesItemModel)
    }

    func addCategory(name: String) throws -> CategoriesItemModel {
        do {
            let resolvedName = Self.normalizedName(name)
            guard !resolvedName.isEmpty else { throw DAO.DBError.unableToCreateCategory }
            let category = try resolveCategory(name: resolvedName)
            category.isRemoved = false
            try modelContext.save()
            return Self.makeCategoriesItemModel(category)
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    func editCategory(item: CategoriesItemModel, name: String) throws -> CategoriesItemModel {
        do {
            let category = try updateCategory(item: item, name: name)
            try modelContext.save()
            return Self.makeCategoriesItemModel(category)
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    func saveCategory(item: CategoriesItemModel?, name: String, goods: [String]) throws -> CategoriesItemModel {
        do {
            let category: Category
            if let item {
                category = try updateCategory(item: item, name: name)
            } else {
                let resolvedName = Self.normalizedName(name)
                guard !resolvedName.isEmpty else { throw DAO.DBError.unableToCreateCategory }
                category = try resolveCategory(name: resolvedName)
            }
            try syncCategoryGoods(category: category, goods: goods)
            try modelContext.save()
            return Self.makeCategoriesItemModel(category)
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    private func updateCategory(item: CategoriesItemModel, name: String) throws -> Category {
        let resolvedName = Self.normalizedName(name)
        guard !resolvedName.isEmpty, let category = try fetchCategory(id: item.id) else { throw DAO.DBError.unableToGetCategory }
        category.name = resolvedName
        category.canonicalName = Self.canonicalName(resolvedName)
        category.isRemoved = false
        return category
    }

    private func resolveCategory(name: String, categoriesByCanonicalName: [String: Category]? = nil) throws -> Category {
        let resolvedName = Self.normalizedName(name)
        let canonicalName = Self.canonicalName(resolvedName)
        if let category = categoriesByCanonicalName?[canonicalName] {
            category.name = resolvedName
            category.canonicalName = canonicalName
            category.isRemoved = false
            return category
        }
        if let category = try fetchCategory(canonicalName: canonicalName) {
            category.name = resolvedName
            category.canonicalName = canonicalName
            category.isRemoved = false
            return category
        }
        let category = Category(name: resolvedName)
        category.canonicalName = canonicalName
        modelContext.insert(category)
        return category
    }

    private func resolveCategories(names: [String]) throws -> [Category] {
        let categoriesByCanonicalName = try resolveCategoriesByCanonicalName(names: names)
        return Self.normalizedNames(names).compactMap { name in
            categoriesByCanonicalName[Self.canonicalName(name)]
        }
    }

    private func resolveCategoriesByCanonicalName(names: [String]) throws -> [String: Category] {
        let normalizedNames = Self.normalizedNames(names)
        let canonicalNames = Set(normalizedNames.map(Self.canonicalName))
        var categoriesByCanonicalName = try fetchCategories(canonicalNames: canonicalNames)

        for name in normalizedNames {
            let canonicalName = Self.canonicalName(name)
            if let category = categoriesByCanonicalName[canonicalName] {
                category.name = name
                category.canonicalName = canonicalName
                category.isRemoved = false
            } else {
                let category = Category(name: name)
                category.canonicalName = canonicalName
                modelContext.insert(category)
                categoriesByCanonicalName[canonicalName] = category
            }
        }

        return categoriesByCanonicalName
    }

    private func fetchCategories(canonicalNames: Set<String>) throws -> [String: Category] {
        guard !canonicalNames.isEmpty else { return [:] }
        let canonicalNames = Array(canonicalNames)
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate { canonicalNames.contains($0.canonicalName) }
        )
        return try modelContext.fetch(descriptor).reduce(into: [:]) { result, category in
            result[category.canonicalName, default: category] = category
        }
    }

    private func fetchCategory(canonicalName: String) throws -> Category? {
        var descriptor = FetchDescriptor<Category>(predicate: #Predicate { $0.canonicalName == canonicalName })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func fetchCategory(id: String) throws -> Category? {
        try fetchModel(id: id, as: Category.self)
    }

    func removeCategory(item: CategoriesItemModel) throws {
        do {
            guard let category = try fetchCategory(id: item.id) else { throw DAO.DBError.unableToGetCategory }
            category.isRemoved = true
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    func getCategoryGoods(item: CategoriesItemModel) throws -> [GoodsItemModel] {
        guard let category = try fetchCategory(id: item.id) else { throw DAO.DBError.unableToGetCategory }
        return (category.goods ?? [])
            .filter { !$0.isRemoved }
            .sorted { $0.name < $1.name }
            .map(Self.makeGoodsItemModel)
    }

    func syncCategoryGoods(item: CategoriesItemModel, goods: [String]) throws {
        do {
            guard let category = try fetchCategory(id: item.id) else { throw DAO.DBError.unableToGetCategory }
            try syncCategoryGoods(category: category, goods: goods)
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    private func syncCategoryGoods(category: Category, goods: [String]) throws {
        let goods = try resolveGoods(names: goods)
        let resolvedGoods = Set(goods.map(\.persistentModelID))
        for existingGood in category.goods ?? [] where !resolvedGoods.contains(existingGood.persistentModelID) {
            existingGood.category = nil
        }
        category.goods = goods
        for good in goods {
            good.category = category
        }
    }

    func getStores(search: String, limit: Int? = nil) throws -> [StoresItemModel] {
        let search = Self.canonicalName(search)
        var descriptor = search.isEmpty
            ? FetchDescriptor<Store>(predicate: #Predicate { !$0.isRemoved && !$0.name.isEmpty }, sortBy: [SortDescriptor(\.name)])
            : FetchDescriptor<Store>(predicate: #Predicate { !$0.isRemoved && !$0.name.isEmpty && $0.canonicalName.contains(search) }, sortBy: [SortDescriptor(\.name)])
        if let limit {
            descriptor.fetchLimit = limit
        }
        return try modelContext.fetch(descriptor).map(Self.makeStoresItemModel)
    }

    func addStore(name: String) throws -> StoresItemModel {
        do {
            let resolvedName = Self.normalizedName(name)
            guard !resolvedName.isEmpty else { throw DAO.DBError.unableToCreateStore }
            let store = try resolveStore(name: resolvedName)
            store.isRemoved = false
            try modelContext.save()
            return Self.makeStoresItemModel(store)
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    func editStore(item: StoresItemModel, name: String) throws -> StoresItemModel {
        do {
            let store = try updateStore(item: item, name: name)
            try modelContext.save()
            return Self.makeStoresItemModel(store)
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    func saveStore(item: StoresItemModel?, name: String, categories: [String]) throws -> StoresItemModel {
        do {
            let store: Store
            if let item {
                store = try updateStore(item: item, name: name)
            } else {
                let resolvedName = Self.normalizedName(name)
                guard !resolvedName.isEmpty else { throw DAO.DBError.unableToCreateStore }
                store = try resolveStore(name: resolvedName)
            }
            try syncStoreCategories(store: store, categories: categories)
            try modelContext.save()
            return Self.makeStoresItemModel(store)
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    private func updateStore(item: StoresItemModel, name: String) throws -> Store {
        let resolvedName = Self.normalizedName(name)
        guard !resolvedName.isEmpty, let store = try fetchStore(id: item.id) else { throw DAO.DBError.unableToGetStore }
        store.name = resolvedName
        store.canonicalName = Self.canonicalName(resolvedName)
        store.isRemoved = false
        return store
    }

    private func resolveStore(name: String, storesByCanonicalName: [String: Store]? = nil) throws -> Store {
        let resolvedName = Self.normalizedName(name)
        let canonicalName = Self.canonicalName(resolvedName)
        if let store = storesByCanonicalName?[canonicalName] {
            store.name = resolvedName
            store.canonicalName = canonicalName
            store.isRemoved = false
            return store
        }
        if let store = try fetchStore(canonicalName: canonicalName) {
            store.name = resolvedName
            store.canonicalName = canonicalName
            store.isRemoved = false
            return store
        }
        let store = Store(name: resolvedName)
        store.canonicalName = canonicalName
        modelContext.insert(store)
        return store
    }

    private func resolveStoresByCanonicalName(names: [String]) throws -> [String: Store] {
        let normalizedNames = Self.normalizedNames(names)
        let canonicalNames = Set(normalizedNames.map(Self.canonicalName))
        var storesByCanonicalName = try fetchStores(canonicalNames: canonicalNames)

        for name in normalizedNames {
            let canonicalName = Self.canonicalName(name)
            if let store = storesByCanonicalName[canonicalName] {
                store.name = name
                store.canonicalName = canonicalName
                store.isRemoved = false
            } else {
                let store = Store(name: name)
                store.canonicalName = canonicalName
                modelContext.insert(store)
                storesByCanonicalName[canonicalName] = store
            }
        }

        return storesByCanonicalName
    }

    private func fetchStores(canonicalNames: Set<String>) throws -> [String: Store] {
        guard !canonicalNames.isEmpty else { return [:] }
        let canonicalNames = Array(canonicalNames)
        let descriptor = FetchDescriptor<Store>(
            predicate: #Predicate { canonicalNames.contains($0.canonicalName) }
        )
        return try modelContext.fetch(descriptor).reduce(into: [:]) { result, store in
            result[store.canonicalName, default: store] = store
        }
    }

    private func fetchStore(canonicalName: String) throws -> Store? {
        var descriptor = FetchDescriptor<Store>(predicate: #Predicate { $0.canonicalName == canonicalName })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func fetchStore(id: String) throws -> Store? {
        try fetchModel(id: id, as: Store.self)
    }

    func removeStore(item: StoresItemModel) throws {
        do {
            guard let store = try fetchStore(id: item.id) else { throw DAO.DBError.unableToGetStore }
            store.isRemoved = true
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    func getStoreCategories(item: StoresItemModel) throws -> [CategoriesItemModel] {
        guard let store = try fetchStore(id: item.id) else { throw DAO.DBError.unableToGetStore }
        return (store.orders ?? [])
            .sorted { $0.order < $1.order }
            .compactMap(\.category)
            .filter { !$0.isRemoved }
            .map(Self.makeCategoriesItemModel)
    }

    func syncStoreCategories(item: StoresItemModel, categories: [String]) throws {
        do {
            guard let store = try fetchStore(id: item.id) else { throw DAO.DBError.unableToGetStore }
            try syncStoreCategories(store: store, categories: categories)
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    private func syncStoreCategories(store: Store, categories: [String]) throws {
        let categories = try resolveCategories(names: categories)
        let resolvedCategories = Set(categories.map(\.persistentModelID))
        var orders = store.orders ?? []

        for order in orders where order.category.map({ resolvedCategories.contains($0.persistentModelID) }) != true {
            modelContext.delete(order)
        }
        orders.removeAll { order in
            order.category.map { resolvedCategories.contains($0.persistentModelID) } != true
        }

        for category in categories where orders.contains(where: { $0.category?.persistentModelID == category.persistentModelID }) == false {
            let order = CategoryStoreOrder(category: category, store: store)
            modelContext.insert(order)
            orders.append(order)
        }

        for (index, category) in categories.enumerated() {
            guard let order = orders.first(where: { $0.category?.persistentModelID == category.persistentModelID }) else {
                throw DAO.DBError.unableToGetOrder
            }
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
