//
//  DAOTest.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 28.10.2021.
//

import XCTest
import Factory
import SwiftData

final class ContextProviderStub: ContextProviderProtocol, @unchecked Sendable {
    private let container: ModelContainer
    
    required init() {
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
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Unable to create in-memory SwiftData container: \(error.localizedDescription)")
        }
    }
    
    func getContext() -> ModelContext {
        ModelContext(container)
    }
}

final class DAOTest: XCTestCase {
    override func setUp() {
        Container.shared.contextProvider.register(factory: { ContextProviderStub() })
        super.setUp()
    }
    
    override func tearDown() {
        Container.shared.reset()
        super.tearDown()
    }
    
    func testAddAndFetchShoppingLists() async throws {
        let dao = DAO()
        let olderDate = Date(timeIntervalSinceReferenceDate: 10)
        let newerDate = Date(timeIntervalSinceReferenceDate: 20)
        
        _ = try await dao.addShoppingList(name: "older", date: olderDate, uniqueId: "older-id")
        let newer = try await dao.addShoppingList(name: "newer", date: newerDate, uniqueId: "newer-id")
        
        let lists = try await dao.getShoppingLists()
        XCTAssertEqual(lists.count, 2)
        XCTAssertEqual(lists.first, newer)
        XCTAssertEqual(lists.map(\.title), ["newer", "older"])
    }
    
    func testRemoveShoppingListHidesItFromFetches() async throws {
        let dao = DAO()
        let list = try await dao.addShoppingList(name: "removed", date: Date(), uniqueId: "removed-id")
        
        try await dao.removeShoppingList(list)
        
        let lists = try await dao.getShoppingLists()
        XCTAssertTrue(lists.isEmpty)
    }
    
    func testAddShoppingListItemCreatesRelatedGoodAndStore() async throws {
        let dao = DAO()
        let list = try await dao.addShoppingList(name: "Groceries", date: Date(), uniqueId: "groceries-id")
        
        try await dao.addShoppingListItem(list: list,
                                          name: "Apples",
                                          amount: "2.5",
                                          store: "Market",
                                          isWeight: true,
                                          price: "3.25",
                                          isImportant: true,
                                          rating: 4,
                                          isPurchased: false,
                                          uniqueId: "apples-id")
        
        let items = try await dao.getShoppingListItems(list: list)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.title, "Apples")
        XCTAssertEqual(items.first?.store, "Market")
        XCTAssertEqual(items.first?.amount, "2.5")
        XCTAssertEqual(items.first?.isImportant, true)
        XCTAssertEqual(items.first?.rating, 4)
    }

    func testAddGoodReusesExistingTrimmedName() async throws {
        let dao = DAO()

        let first = try await dao.addGood(name: " Milk ", category: "Dairy")
        let second = try await dao.addGood(name: "Milk", category: "")

        let goods = try await dao.getGoods(search: "")
        XCTAssertEqual(first.id, second.id)
        XCTAssertEqual(goods.count, 1)
        XCTAssertEqual(goods.first?.name, "Milk")
        XCTAssertEqual(goods.first?.category, "Dairy")
    }
    
    func testSyncStoreCategoriesPreservesOrder() async throws {
        let dao = DAO()
        let store = try await dao.addStore(name: "Market")
        
        try await dao.syncStoreCategories(item: store, categories: ["Produce", "Bakery", "Frozen"])
        
        let categories = try await dao.getStoreCategories(item: store)
        XCTAssertEqual(categories.map(\.name), ["Produce", "Bakery", "Frozen"])
    }

    func testSyncStoreCategoriesTrimsAndDeduplicatesNames() async throws {
        let dao = DAO()
        let store = try await dao.addStore(name: "Market")

        try await dao.syncStoreCategories(item: store, categories: [" Produce ", "produce", "", "Bakery"])

        let categories = try await dao.getStoreCategories(item: store)
        XCTAssertEqual(categories.map(\.name), ["Produce", "Bakery"])
    }
}
