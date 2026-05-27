//
//  DAOStub.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 26.05.2026.
//

import Foundation

#if DEBUG
@MainActor
final class DAOStub: DAOProtocol {
    var shoppingLists: [ShoppingListModel] = [
        ShoppingListModel(id: "preview-list", name: "Preview list", date: Date())
    ]
    var shoppingListItems: [ShoppingListItemModel] = [
        ShoppingListItemModel(
            id: "preview-item",
            title: "Milk",
            store: "Market",
            category: "Dairy",
            categoryStoreOrder: 0,
            isPurchased: false,
            amount: "1",
            isWeight: false,
            price: "2.50",
            isImportant: true,
            rating: 4
        )
    ]
    var goods: [GoodsItemModel] = [
        GoodsItemModel(id: "preview-good", name: "Milk", category: "Dairy")
    ]
    var categories: [CategoriesItemModel] = [
        CategoriesItemModel(id: "preview-category", name: "Dairy")
    ]
    var stores: [StoresItemModel] = [
        StoresItemModel(id: "preview-store", name: "Market")
    ]
    var categoryGoods: [String: [GoodsItemModel]] = [:]
    var storeCategories: [String: [CategoriesItemModel]] = [:]

    func getShoppingLists() async throws -> [ShoppingListModel] {
        shoppingLists
    }

    func addShoppingList(name: String, date: Date) async throws -> ShoppingListModel {
        let list = ShoppingListModel(id: UUID().uuidString, name: name, date: date)
        shoppingLists.append(list)
        return list
    }

    func importShoppingList(name: String, date: Date, items: [ShoppingListImportItem]) async throws -> ShoppingListModel {
        let imported = try await importShoppingLists([ShoppingListImport(name: name, date: date, items: items)])
        if let list = imported.first {
            return list
        }
        return try await addShoppingList(name: name, date: date)
    }

    func importShoppingLists(_ lists: [ShoppingListImport]) async throws -> [ShoppingListModel] {
        var imported: [ShoppingListModel] = []
        for importModel in lists {
            let list = try await addShoppingList(name: importModel.name, date: importModel.date)
            imported.append(list)
            for item in importModel.items {
                try await addShoppingListItem(
                    list: list,
                    name: item.name,
                    amount: "\(item.amount)",
                    store: item.store,
                    isWeight: item.isWeight,
                    price: "\(item.price)",
                    isImportant: item.isImportant,
                    rating: 0,
                    isPurchased: item.isPurchased
                )
            }
        }
        return imported
    }

    func removeShoppingList(_ item: ShoppingListModel) async throws {
        shoppingLists.removeAll { $0.id == item.id }
    }

    func getShoppingListItems(list: ShoppingListModel) async throws -> [ShoppingListItemModel] {
        shoppingListItems
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
        shoppingListItems.append(
            ShoppingListItemModel(
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
            )
        )
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
        shoppingListItems = shoppingListItems.map {
            guard $0.id == item.id else { return $0 }
            return ShoppingListItemModel(
                id: item.id,
                title: name,
                store: store,
                category: item.category,
                categoryStoreOrder: item.categoryStoreOrder,
                isPurchased: item.isPurchased,
                amount: amount,
                isWeight: isWeight,
                price: price,
                isImportant: isImportant,
                rating: rating
            )
        }
    }

    func removeShoppingListItem(item: ShoppingListItemModel) async throws {
        shoppingListItems.removeAll { $0.id == item.id }
    }

    func togglePurchasedShoppingListItem(item: ShoppingListItemModel) async throws {
        shoppingListItems = shoppingListItems.map {
            guard $0.id == item.id else { return $0 }
            return ShoppingListItemModel(
                id: $0.id,
                title: $0.title,
                store: $0.store,
                category: $0.category,
                categoryStoreOrder: $0.categoryStoreOrder,
                isPurchased: !$0.isPurchased,
                amount: $0.amount,
                isWeight: $0.isWeight,
                price: $0.price,
                isImportant: $0.isImportant,
                rating: $0.rating
            )
        }
    }

    func getGoods(search: String, limit: Int?) async throws -> [GoodsItemModel] {
        let result = search.isEmpty ? goods : goods.filter { $0.name.localizedCaseInsensitiveContains(search) }
        return limit.map { Array(result.prefix($0)) } ?? result
    }

    func addGood(name: String, category: String) async throws -> GoodsItemModel {
        let item = GoodsItemModel(id: UUID().uuidString, name: name, category: category)
        goods.append(item)
        return item
    }

    func editGood(item: GoodsItemModel, name: String, category: String) async throws -> GoodsItemModel {
        let edited = GoodsItemModel(id: item.id, name: name, category: category)
        goods = goods.map { $0.id == item.id ? edited : $0 }
        return edited
    }

    func removeGood(item: GoodsItemModel) async throws {
        goods.removeAll { $0.id == item.id }
    }

    func getCategories(search: String, limit: Int?) async throws -> [CategoriesItemModel] {
        let result = search.isEmpty ? categories : categories.filter { $0.name.localizedCaseInsensitiveContains(search) }
        return limit.map { Array(result.prefix($0)) } ?? result
    }

    func addCategory(name: String) async throws -> CategoriesItemModel {
        let item = CategoriesItemModel(id: UUID().uuidString, name: name)
        categories.append(item)
        return item
    }

    func editCategory(item: CategoriesItemModel, name: String) async throws -> CategoriesItemModel {
        let edited = CategoriesItemModel(id: item.id, name: name)
        categories = categories.map { $0.id == item.id ? edited : $0 }
        return edited
    }

    func saveCategory(item: CategoriesItemModel?, name: String, goods: [String]) async throws -> CategoriesItemModel {
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
        categories.removeAll { $0.id == item.id }
    }

    func getCategoryGoods(item: CategoriesItemModel) async throws -> [GoodsItemModel] {
        categoryGoods[item.id] ?? goods
    }

    func syncCategoryGoods(item: CategoriesItemModel, goods: [String]) async throws {
        categoryGoods[item.id] = goods.map { GoodsItemModel(id: UUID().uuidString, name: $0, category: item.name) }
    }

    func getStores(search: String, limit: Int?) async throws -> [StoresItemModel] {
        let result = search.isEmpty ? stores : stores.filter { $0.name.localizedCaseInsensitiveContains(search) }
        return limit.map { Array(result.prefix($0)) } ?? result
    }

    func addStore(name: String) async throws -> StoresItemModel {
        let item = StoresItemModel(id: UUID().uuidString, name: name)
        stores.append(item)
        return item
    }

    func editStore(item: StoresItemModel, name: String) async throws -> StoresItemModel {
        let edited = StoresItemModel(id: item.id, name: name)
        stores = stores.map { $0.id == item.id ? edited : $0 }
        return edited
    }

    func saveStore(item: StoresItemModel?, name: String, categories: [String]) async throws -> StoresItemModel {
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
        stores.removeAll { $0.id == item.id }
    }

    func getStoreCategories(item: StoresItemModel) async throws -> [CategoriesItemModel] {
        storeCategories[item.id] ?? categories
    }

    func syncStoreCategories(item: StoresItemModel, categories: [String]) async throws {
        storeCategories[item.id] = categories.map { CategoriesItemModel(id: UUID().uuidString, name: $0) }
    }
}
#endif
