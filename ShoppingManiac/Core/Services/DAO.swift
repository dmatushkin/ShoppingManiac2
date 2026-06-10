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
protocol DAOProtocol: Sendable {
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
    private lazy var dataStore = ShoppingDataStore(modelContainer: contextProvider.getContainer())

    nonisolated required init() {}

    static func persistentIDString<T: PersistentModel>(_ model: T) -> String {
        ShoppingDataStore.persistentIDString(model)
    }

    func getShoppingLists() async throws -> [ShoppingListModel] {
        try await dataStore.getShoppingLists()
    }

    func addShoppingList(name: String, date: Date) async throws -> ShoppingListModel {
        try await dataStore.addShoppingList(name: name, date: date)
    }

    func importShoppingList(name: String, date: Date, items: [ShoppingListImportItem]) async throws -> ShoppingListModel {
        try await dataStore.importShoppingList(name: name, date: date, items: items)
    }

    func importShoppingLists(_ lists: [ShoppingListImport]) async throws -> [ShoppingListModel] {
        try await dataStore.importShoppingLists(lists)
    }

    func removeShoppingList(_ item: ShoppingListModel) async throws {
        try await dataStore.removeShoppingList(item)
    }

    func getShoppingListItems(list: ShoppingListModel) async throws -> [ShoppingListItemModel] {
        try await dataStore.getShoppingListItems(list: list)
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
        try await dataStore.addShoppingListItem(list: list,
                                                name: name,
                                                amount: amount,
                                                store: store,
                                                isWeight: isWeight,
                                                price: price,
                                                isImportant: isImportant,
                                                rating: rating,
                                                isPurchased: isPurchased)
    }

    func editShoppingListItem(item: ShoppingListItemModel,
                              name: String,
                              amount: String,
                              store: String,
                              isWeight: Bool,
                              price: String,
                              isImportant: Bool,
                              rating: Int) async throws {
        try await dataStore.editShoppingListItem(item: item,
                                                 name: name,
                                                 amount: amount,
                                                 store: store,
                                                 isWeight: isWeight,
                                                 price: price,
                                                 isImportant: isImportant,
                                                 rating: rating)
    }

    func removeShoppingListItem(item: ShoppingListItemModel) async throws {
        try await dataStore.removeShoppingListItem(item: item)
    }

    func togglePurchasedShoppingListItem(item: ShoppingListItemModel) async throws {
        try await dataStore.togglePurchasedShoppingListItem(item: item)
    }

    func getGoods(search: String, limit: Int? = nil) async throws -> [GoodsItemModel] {
        try await dataStore.getGoods(search: search, limit: limit)
    }

    func addGood(name: String, category: String) async throws -> GoodsItemModel {
        try await dataStore.addGood(name: name, category: category)
    }

    func editGood(item: GoodsItemModel, name: String, category: String) async throws -> GoodsItemModel {
        try await dataStore.editGood(item: item, name: name, category: category)
    }

    func removeGood(item: GoodsItemModel) async throws {
        try await dataStore.removeGood(item: item)
    }

    func getCategories(search: String, limit: Int? = nil) async throws -> [CategoriesItemModel] {
        try await dataStore.getCategories(search: search, limit: limit)
    }

    func addCategory(name: String) async throws -> CategoriesItemModel {
        try await dataStore.addCategory(name: name)
    }

    func editCategory(item: CategoriesItemModel, name: String) async throws -> CategoriesItemModel {
        try await dataStore.editCategory(item: item, name: name)
    }

    func saveCategory(item: CategoriesItemModel?, name: String, goods: [String]) async throws -> CategoriesItemModel {
        try await dataStore.saveCategory(item: item, name: name, goods: goods)
    }

    func removeCategory(item: CategoriesItemModel) async throws {
        try await dataStore.removeCategory(item: item)
    }

    func getCategoryGoods(item: CategoriesItemModel) async throws -> [GoodsItemModel] {
        try await dataStore.getCategoryGoods(item: item)
    }

    func syncCategoryGoods(item: CategoriesItemModel, goods: [String]) async throws {
        try await dataStore.syncCategoryGoods(item: item, goods: goods)
    }

    func getStores(search: String, limit: Int? = nil) async throws -> [StoresItemModel] {
        try await dataStore.getStores(search: search, limit: limit)
    }

    func addStore(name: String) async throws -> StoresItemModel {
        try await dataStore.addStore(name: name)
    }

    func editStore(item: StoresItemModel, name: String) async throws -> StoresItemModel {
        try await dataStore.editStore(item: item, name: name)
    }

    func saveStore(item: StoresItemModel?, name: String, categories: [String]) async throws -> StoresItemModel {
        try await dataStore.saveStore(item: item, name: name, categories: categories)
    }

    func removeStore(item: StoresItemModel) async throws {
        try await dataStore.removeStore(item: item)
    }

    func getStoreCategories(item: StoresItemModel) async throws -> [CategoriesItemModel] {
        try await dataStore.getStoreCategories(item: item)
    }

    func syncStoreCategories(item: StoresItemModel, categories: [String]) async throws {
        try await dataStore.syncStoreCategories(item: item, categories: categories)
    }
}
