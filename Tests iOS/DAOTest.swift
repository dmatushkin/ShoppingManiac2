//
//  DAOTest.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 28.10.2021.
//

import XCTest
import DependencyInjection
import CoreData

final class ContextProviderStub: ContextProviderProtocol, DIDependency {
    
    private var container: NSPersistentContainer!
    
    required init() {
        guard let modelURL = Bundle(for: Self.self).url(forResource: "ShoppingManiac", withExtension: "momd"), let model = NSManagedObjectModel(contentsOf: modelURL) else { return }
        container = NSPersistentContainer(name: "ShoppingManiac", managedObjectModel: model)
        container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
    }
    
    func getContext() -> NSManagedObjectContext {
        return container.viewContext
    }
}

final class DAOTest: XCTestCase {
    
    @Autowired(cacheType: .share) private var contextProvider: ContextProviderProtocol
        
    override func setUp() {
        DIProvider.shared
            .register(forType: ContextProviderProtocol.self, dependency: ContextProviderStub.self)
        super.setUp()
    }
    
    override func tearDown() {
        DIProvider.shared.clear()
        super.tearDown()
    }
    
    func testGetShoppingLists() async throws {
        // arrange
        let context = contextProvider.getContext()
        let list1 = NSEntityDescription.insertNewObject(forEntityName: "ShoppingList", into: context) as? ShoppingList
        list1?.date = 10
        let list2 = NSEntityDescription.insertNewObject(forEntityName: "ShoppingList", into: context) as? ShoppingList
        list2?.name = "name2"
        list2?.date = 20
        let list3 = NSEntityDescription.insertNewObject(forEntityName: "ShoppingList", into: context) as? ShoppingList
        list3?.name = "name3"
        list3?.date = 30
        let list4 = NSEntityDescription.insertNewObject(forEntityName: "ShoppingList", into: context) as? ShoppingList
        list4?.name = "name4"
        list4?.date = 40
        let list5 = NSEntityDescription.insertNewObject(forEntityName: "ShoppingList", into: context) as? ShoppingList
        list5?.name = "name5"
        list5?.date = 50
        let dao = DAO()
        
        // act
        let lists = try await dao.getShoppingLists()
        
        // assert
        XCTAssertEqual(lists.count, 5)
        XCTAssertEqual(lists[0].title, "name5")
        XCTAssertEqual(lists[0].id, list5?.objectID)
        XCTAssertEqual(lists[1].title, "name4")
        XCTAssertEqual(lists[1].id, list4?.objectID)
        XCTAssertEqual(lists[2].title, "name3")
        XCTAssertEqual(lists[2].id, list3?.objectID)
        XCTAssertEqual(lists[3].title, "name2")
        XCTAssertEqual(lists[3].id, list2?.objectID)
        XCTAssertEqual(lists[4].title, "Jan 1, 2001")
        XCTAssertEqual(lists[4].id, list1?.objectID)
    }
    
    func testAddShoppingList() async throws {
        // arrange
        let dao = DAO()
        
        // act
        let model = try await dao.addShoppingList(name: "test1")
        
        // assert
        XCTAssertEqual(model.title, "test1")
        let context = contextProvider.getContext()
        let request: NSFetchRequest<ShoppingList> = ShoppingList.fetchRequest()
        let items = try context.fetch(request)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].isRemoved, false)
        XCTAssertEqual(items[0].name, "test1")
        XCTAssertEqual(items[0].objectID, model.id)
    }
    
    func testRemoveShoppingList() async throws {
        // arrange
        let context = contextProvider.getContext()
        let list1 = NSEntityDescription.insertNewObject(forEntityName: "ShoppingList", into: context) as? ShoppingList
        let model = ShoppingListModel(id: list1!.objectID, title: "test")
        let dao = DAO()
        
        // act
        try await dao.removeShoppingList(model)
        
        // assert
        let request: NSFetchRequest<ShoppingList> = ShoppingList.fetchRequest()
        let items = try context.fetch(request)
        XCTAssertEqual(items.first?.isRemoved, true)
    }
    
    func testGetShoppingListItems() async throws {
        // arrange
        let context = contextProvider.getContext()
        let list1 = NSEntityDescription.insertNewObject(forEntityName: "ShoppingList", into: context) as? ShoppingList
        let model = ShoppingListModel(id: list1!.objectID, title: "test")
        let item1 = NSEntityDescription.insertNewObject(forEntityName: "ShoppingListItem", into: context) as? ShoppingListItem
        let good1 = NSEntityDescription.insertNewObject(forEntityName: "Good", into: context) as? Good
        let store1 = NSEntityDescription.insertNewObject(forEntityName: "Store", into: context) as? Store
        let category1 = NSEntityDescription.insertNewObject(forEntityName: "Category", into: context) as? Category
        category1?.name = "category1"
        store1?.name = "store1"
        item1?.store = store1
        good1?.name = "test1"
        good1?.category = category1
        item1?.good = good1
        item1?.list = list1
        item1?.purchased = true
        item1?.quantity = 5
        let item2 = NSEntityDescription.insertNewObject(forEntityName: "ShoppingListItem", into: context) as? ShoppingListItem
        let good2 = NSEntityDescription.insertNewObject(forEntityName: "Good", into: context) as? Good
        let store2 = NSEntityDescription.insertNewObject(forEntityName: "Store", into: context) as? Store
        let category2 = NSEntityDescription.insertNewObject(forEntityName: "Category", into: context) as? Category
        category2?.name = "category2"
        store2?.name = "store2"
        item2?.store = store2
        good2?.name = "test2"
        good2?.category = category2
        item2?.good = good2
        item2?.list = list1
        item2?.purchased = false
        item2?.quantity = 6
        let item3 = NSEntityDescription.insertNewObject(forEntityName: "ShoppingListItem", into: context) as? ShoppingListItem
        let good3 = NSEntityDescription.insertNewObject(forEntityName: "Good", into: context) as? Good
        let store3 = NSEntityDescription.insertNewObject(forEntityName: "Store", into: context) as? Store
        let category3 = NSEntityDescription.insertNewObject(forEntityName: "Category", into: context) as? Category
        category3?.name = "category3"
        store3?.name = "store3"
        item3?.store = store3
        good3?.name = "test3"
        good3?.category = category3
        item3?.good = good3
        item3?.list = list1
        let item4 = NSEntityDescription.insertNewObject(forEntityName: "ShoppingListItem", into: context) as? ShoppingListItem
        item4?.isRemoved = true
        item4?.list = list1
        let dao = DAO()
        
        // act
        let list = try await dao.getShoppingListItems(list: model).sorted(by: { $0.title < $1.title })
        
        // assert
        XCTAssertEqual(list.count, 3)
        XCTAssertEqual(list[0].id, item1?.objectID)
        XCTAssertEqual(list[0].title, "test1")
        XCTAssertEqual(list[0].store, "store1")
        XCTAssertEqual(list[0].category, "category1")
        XCTAssertEqual(list[0].isPurchased, true)
        XCTAssertEqual(list[0].amount, "5.0")
        XCTAssertEqual(list[1].id, item2?.objectID)
        XCTAssertEqual(list[1].title, "test2")
        XCTAssertEqual(list[1].store, "store2")
        XCTAssertEqual(list[1].category, "category2")
        XCTAssertEqual(list[1].isPurchased, false)
        XCTAssertEqual(list[1].amount, "6.0")
        XCTAssertEqual(list[2].id, item3?.objectID)
        XCTAssertEqual(list[2].title, "test3")
        XCTAssertEqual(list[2].store, "store3")
        XCTAssertEqual(list[2].category, "category3")
        XCTAssertEqual(list[2].isPurchased, false)
        XCTAssertEqual(list[2].amount, "0.0")
    }
    
    func testAddShoppingListItem() async throws {
        // arrange
        let context = contextProvider.getContext()
        let list1 = NSEntityDescription.insertNewObject(forEntityName: "ShoppingList", into: context) as? ShoppingList
        let model = ShoppingListModel(id: list1!.objectID, title: "test")
        let dao = DAO()
        
        // act
        try await dao.addShoppingListItem(list: model, name: "test", amount: "15", store: "test store", isWeight: false, price: "25", isImportant: false, rating: 5)
        
        // assert
        let request: NSFetchRequest<ShoppingListItem> = ShoppingListItem.fetchRequest()
        let items = try context.fetch(request)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.list, list1)
        XCTAssertEqual(items.first?.good?.name, "test")
        XCTAssertEqual(items.first?.quantity, 15)
        XCTAssertEqual(items.first?.store?.name, "test store")
        XCTAssertEqual(items.first?.isWeight, false)
        XCTAssertEqual(items.first?.price, 25)
        XCTAssertEqual(items.first?.isImportant, false)
        XCTAssertEqual(items.first?.good?.personalRating, 5)
    }
    
    func testRemoveShoppingListItem() async throws {
        // arrange
        let context = contextProvider.getContext()
        let item1 = NSEntityDescription.insertNewObject(forEntityName: "ShoppingListItem", into: context) as? ShoppingListItem
        let model = ShoppingListItemModel(id: item1!.objectID, title: "", store: "", category: "", categoryStoreOrder: 0, isPurchased: false, amount: "15", isWeight: false, price: "15", isImportant: false, rating: 5)
        let dao = DAO()
        
        // act
        try await dao.removeShoppingListItem(item: model)
        
        // assert
        let request: NSFetchRequest<ShoppingListItem> = ShoppingListItem.fetchRequest()
        let items = try context.fetch(request)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.isRemoved, true)
    }
    
    func testTogglePurchasedItemTrue() async throws {
        // arrange
        let context = contextProvider.getContext()
        let item1 = NSEntityDescription.insertNewObject(forEntityName: "ShoppingListItem", into: context) as? ShoppingListItem
        item1?.purchased = true
        let model = ShoppingListItemModel(id: item1!.objectID, title: "", store: "", category: "", categoryStoreOrder: 0, isPurchased: false, amount: "15", isWeight: false, price: "15", isImportant: false, rating: 5)
        let dao = DAO()
        
        // act
        try await dao.togglePurchasedShoppingListItem(item: model)
        
        // assert
        let request: NSFetchRequest<ShoppingListItem> = ShoppingListItem.fetchRequest()
        let items = try context.fetch(request)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.purchased, false)
    }
    
    func testTogglePurchasedItemFalse() async throws {
        // arrange
        let context = contextProvider.getContext()
        let item1 = NSEntityDescription.insertNewObject(forEntityName: "ShoppingListItem", into: context) as? ShoppingListItem
        item1?.purchased = false
        let model = ShoppingListItemModel(id: item1!.objectID, title: "", store: "", category: "", categoryStoreOrder: 0, isPurchased: false, amount: "15", isWeight: false, price: "15", isImportant: false, rating: 5)
        let dao = DAO()
        
        // act
        try await dao.togglePurchasedShoppingListItem(item: model)
        
        // assert
        let request: NSFetchRequest<ShoppingListItem> = ShoppingListItem.fetchRequest()
        let items = try context.fetch(request)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.purchased, true)
    }
    
    func testGetGoods() async throws {
        // arrange
        let context = contextProvider.getContext()
        let good1 = NSEntityDescription.insertNewObject(forEntityName: "Good", into: context) as? Good
        good1?.name = "test1"
        let good2 = NSEntityDescription.insertNewObject(forEntityName: "Good", into: context) as? Good
        good2?.name = "test2"
        let good3 = NSEntityDescription.insertNewObject(forEntityName: "Good", into: context) as? Good
        good3?.name = "test3"
        let dao = DAO()
        
        // act
        let items = try await dao.getGoods()
        
        // assert
        XCTAssertEqual(items.count, 3)
        XCTAssertEqual(items[0].id, good1?.objectID)
        XCTAssertEqual(items[0].name, "test1")
        XCTAssertEqual(items[1].id, good2?.objectID)
        XCTAssertEqual(items[1].name, "test2")
        XCTAssertEqual(items[2].id, good3?.objectID)
        XCTAssertEqual(items[2].name, "test3")
    }
    
    func testAddGood() async throws {
        // arrange
        let dao = DAO()
        
        // act
        let model = try await dao.addGood(name: "test1", category: "test2")
        
        // assert
        XCTAssertEqual(model.name, "test1")
        XCTAssertEqual(model.category, "test2")
        let context = contextProvider.getContext()
        let request: NSFetchRequest<Good> = Good.fetchRequest()
        let items = try context.fetch(request)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.name, "test1")
        XCTAssertEqual(items.first?.category?.name, "test2")
        XCTAssertEqual(model.id, items.first?.objectID)
    }
    
    func testEditGood() async throws {
        // arrange
        let context = contextProvider.getContext()
        let good1 = NSEntityDescription.insertNewObject(forEntityName: "Good", into: context) as? Good
        good1?.name = "test1"
        let model = GoodsItemModel(id: good1!.objectID, name: "", category: "")
        let dao = DAO()
        
        // act
        let result = try await dao.editGood(item: model, name: "test3", category: "test4")
        
        // assert
        XCTAssertEqual(result.id, good1?.objectID)
        XCTAssertEqual(result.name, "test3")
        XCTAssertEqual(result.category, "test4")
        let request: NSFetchRequest<Good> = Good.fetchRequest()
        let items = try context.fetch(request)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(result.id, items.first?.objectID)
        XCTAssertEqual(items.first?.name, "test3")
        XCTAssertEqual(items.first?.category?.name, "test4")
    }
    
    func testRemoveGood() async throws {
        // arrange
        let context = contextProvider.getContext()
        let good1 = NSEntityDescription.insertNewObject(forEntityName: "Good", into: context) as? Good
        good1?.name = "test1"
        let item1 = NSEntityDescription.insertNewObject(forEntityName: "ShoppingListItem", into: context) as? ShoppingListItem
        item1?.good = good1
        let model = GoodsItemModel(id: good1!.objectID, name: "", category: "")
        let dao = DAO()
        
        // act
        try await dao.removeGood(item: model)
        
        // assert
        let goodRequest: NSFetchRequest<Good> = Good.fetchRequest()
        let goodItems = try context.fetch(goodRequest)
        XCTAssertEqual(goodItems.count, 0)
        let shoppingRequest: NSFetchRequest<ShoppingListItem> = ShoppingListItem.fetchRequest()
        let shoppingItems = try context.fetch(shoppingRequest)
        XCTAssertEqual(shoppingItems.count, 1)
        XCTAssertEqual(shoppingItems.first?.isRemoved, true)
    }
    
    func testGetCategories() async throws {
        // arrange
        let context = contextProvider.getContext()
        let category1 = NSEntityDescription.insertNewObject(forEntityName: "Category", into: context) as? Category
        category1?.name = "test1"
        let category2 = NSEntityDescription.insertNewObject(forEntityName: "Category", into: context) as? Category
        category2?.name = "test2"
        let category3 = NSEntityDescription.insertNewObject(forEntityName: "Category", into: context) as? Category
        category3?.name = "test3"
        let dao = DAO()
        
        // act
        let items = try await dao.getCategories()
        
        // assert
        XCTAssertEqual(items.count, 3)
        XCTAssertEqual(items[0].id, category1?.objectID)
        XCTAssertEqual(items[0].name, "test1")
        XCTAssertEqual(items[1].id, category2?.objectID)
        XCTAssertEqual(items[1].name, "test2")
        XCTAssertEqual(items[2].id, category3?.objectID)
        XCTAssertEqual(items[2].name, "test3")
    }
    
    func testAddCategory() async throws {
        // arrange
        let dao = DAO()
        
        // act
        let model = try await dao.addCategory(name: "test1")
        
        // assert
        XCTAssertEqual(model.name, "test1")
        let context = contextProvider.getContext()
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        let items = try context.fetch(request)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.name, "test1")
        XCTAssertEqual(model.id, items.first?.objectID)
    }
    
    func testEditCategory() async throws {
        // arrange
        let context = contextProvider.getContext()
        let category1 = NSEntityDescription.insertNewObject(forEntityName: "Category", into: context) as? Category
        category1?.name = "test1"
        let model = CategoriesItemModel(id: category1!.objectID, name: "")
        let dao = DAO()
        
        // act
        let result = try await dao.editCategory(item: model, name: "test3")
        
        // assert
        XCTAssertEqual(result.id, category1?.objectID)
        XCTAssertEqual(result.name, "test3")
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        let items = try context.fetch(request)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(result.id, items.first?.objectID)
        XCTAssertEqual(items.first?.name, "test3")
    }
    
    func testRemoveCategory() async throws {
        // arrange
        let context = contextProvider.getContext()
        let category1 = NSEntityDescription.insertNewObject(forEntityName: "Category", into: context) as? Category
        category1?.name = "test1"
        let model = CategoriesItemModel(id: category1!.objectID, name: "")
        let dao = DAO()
        
        // act
        try await dao.removeCategory(item: model)
        
        // assert
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        let items = try context.fetch(request)
        XCTAssertEqual(items.count, 0)
    }
    
    func testGetStores() async throws {
        // arrange
        let context = contextProvider.getContext()
        let store1 = NSEntityDescription.insertNewObject(forEntityName: "Store", into: context) as? Store
        store1?.name = "test1"
        let store2 = NSEntityDescription.insertNewObject(forEntityName: "Store", into: context) as? Store
        store2?.name = "test2"
        let store3 = NSEntityDescription.insertNewObject(forEntityName: "Store", into: context) as? Store
        store3?.name = "test3"
        let dao = DAO()
        
        // act
        let items = try await dao.getStores()
        
        // assert
        XCTAssertEqual(items.count, 3)
        XCTAssertEqual(items[0].id, store1?.objectID)
        XCTAssertEqual(items[0].name, "test1")
        XCTAssertEqual(items[1].id, store2?.objectID)
        XCTAssertEqual(items[1].name, "test2")
        XCTAssertEqual(items[2].id, store3?.objectID)
        XCTAssertEqual(items[2].name, "test3")
    }
    
    func testAddStore() async throws {
        // arrange
        let dao = DAO()
        
        // act
        let model = try await dao.addStore(name: "test1")
        
        // assert
        XCTAssertEqual(model.name, "test1")
        let context = contextProvider.getContext()
        let request: NSFetchRequest<Store> = Store.fetchRequest()
        let items = try context.fetch(request)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.name, "test1")
        XCTAssertEqual(model.id, items.first?.objectID)
    }
    
    func testEditStore() async throws {
        // arrange
        let context = contextProvider.getContext()
        let store1 = NSEntityDescription.insertNewObject(forEntityName: "Store", into: context) as? Store
        store1?.name = "test1"
        let model = StoresItemModel(id: store1!.objectID, name: "")
        let dao = DAO()
        
        // act
        let result = try await dao.editStore(item: model, name: "test3")
        
        // assert
        XCTAssertEqual(result.id, store1?.objectID)
        XCTAssertEqual(result.name, "test3")
        let request: NSFetchRequest<Store> = Store.fetchRequest()
        let items = try context.fetch(request)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(result.id, items.first?.objectID)
        XCTAssertEqual(items.first?.name, "test3")
    }
    
    func testRemoveStore() async throws {
        // arrange
        let context = contextProvider.getContext()
        let store1 = NSEntityDescription.insertNewObject(forEntityName: "Store", into: context) as? Store
        store1?.name = "test1"
        let model = StoresItemModel(id: store1!.objectID, name: "")
        let dao = DAO()
        
        // act
        try await dao.removeStore(item: model)
        
        // assert
        let request: NSFetchRequest<Store> = Store.fetchRequest()
        let items = try context.fetch(request)
        XCTAssertEqual(items.count, 0)
    }
}
