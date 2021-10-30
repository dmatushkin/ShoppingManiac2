//
//  DAO.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 10.10.2021.
//

import Foundation
import CoreData
import DependencyInjection
import CommonError

protocol DAOProtocol {
    func getShoppingLists() async throws -> [ShoppingListModel]
    func addShoppingList(name: String) async throws -> ShoppingListModel
    func removeShoppingList(_ item: ShoppingListModel) async throws
    func getShoppingListItems(list: ShoppingListModel) async throws -> [ShoppingListItemModel]
    func addShoppingListItem(list: ShoppingListModel,
                             name: String,
                             amount: String,
                             store: String,
                             isWeight: Bool,
                             price: String,
                             isImportant: Bool,
                             rating: Int) async throws
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
    func getGoods() async throws -> [GoodsItemModel]
    func addGood(name: String, category: String) async throws -> GoodsItemModel
    func editGood(item: GoodsItemModel, name: String, category: String) async throws -> GoodsItemModel
    func removeGood(item: GoodsItemModel) async throws
    func getCategories() async throws -> [CategoriesItemModel]
    func addCategory(name: String) async throws -> CategoriesItemModel
    func editCategory(item: CategoriesItemModel, name: String) async throws -> CategoriesItemModel
    func removeCategory(item: CategoriesItemModel) async throws
    func getStores() async throws -> [StoresItemModel]
    func addStore(name: String) async throws -> StoresItemModel
    func editStore(item: StoresItemModel, name: String) async throws -> StoresItemModel
    func removeStore(item: StoresItemModel) async throws
}

final class DAO: DAOProtocol, DIDependency {
    
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
    }
    
    @Autowired(cacheType: .share, instantiateOnInit: true) private var contextProvider: ContextProviderProtocol
    
    required init() {}
    
    func getShoppingLists() async throws -> [ShoppingListModel] {
        let context = contextProvider.getContext()
        return try await context.perform({
            let request = NSFetchRequest<ShoppingList>(entityName: "ShoppingList")
            request.predicate = NSPredicate(format: "isRemoved == NO")
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            let items: [ShoppingList] = try context.fetch(request)
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            return items.map({ list in
                ShoppingListModel(id: list.objectID, title: list.name?.nilIfEmpty ?? dateFormatter.string(from: Date(timeIntervalSinceReferenceDate: list.date)) )
            })
        })
    }
    
    func addShoppingList(name: String) async throws -> ShoppingListModel {
        let context = contextProvider.getContext()
        return try await context.perform({
            guard let item = NSEntityDescription.insertNewObject(forEntityName: "ShoppingList", into: context) as? ShoppingList else { throw DBError.unableToCreateShoppingList }
            item.name = name
            item.date = Date().timeIntervalSinceReferenceDate
            try context.save()
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            return ShoppingListModel(id: item.objectID, title: item.name?.nilIfEmpty ?? dateFormatter.string(from: Date(timeIntervalSinceReferenceDate: item.date)) )
        })
    }
    
    func removeShoppingList(_ item: ShoppingListModel) async throws {
        let context = contextProvider.getContext()
        return try await context.perform({
            guard let item = try context.existingObject(with: item.id) as? ShoppingList else { throw DBError.unableToGetShoppingList }
            item.isRemoved = true
            try context.save()
        })
    }
    
    func getShoppingListItems(list: ShoppingListModel) async throws -> [ShoppingListItemModel] {
        let context = contextProvider.getContext()
        return try await context.perform({
            guard let item = try context.existingObject(with: list.id) as? ShoppingList else { throw DBError.unableToGetShoppingList }
            let request = NSFetchRequest<ShoppingListItem>(entityName: "ShoppingListItem")
            request.predicate = NSPredicate(format: "list == %@ AND isRemoved == 0", item)
            let items: [ShoppingListItem] = try context.fetch(request)
            return items.map({ item in
                ShoppingListItemModel(id: item.objectID,
                                      title: item.good?.name ?? "",
                                      store: item.store?.name ?? "",
                                      category: item.good?.category?.name ?? "",
                                      isPurchased: item.purchased,
                                      amount: "\(item.quantity)",
                                      isWeight: item.isWeight,
                                      price: "\(item.price)",
                                      isImportant: item.isImportant,
                                      rating: Int(item.good?.personalRating ?? 0))
            })
        })
    }
    
    func addShoppingListItem(list: ShoppingListModel,
                             name: String,
                             amount: String,
                             store: String,
                             isWeight: Bool,
                             price: String,
                             isImportant: Bool,
                             rating: Int) async throws {
        let context = contextProvider.getContext()
        return try await context.perform({[weak self] in
            guard let shoppingList = try context.existingObject(with: list.id) as? ShoppingList else { throw DBError.unableToGetShoppingList }
            guard !name.isEmpty, let item = NSEntityDescription.insertNewObject(forEntityName: "ShoppingListItem", into: context) as? ShoppingListItem else { throw DBError.unableToCreateShoppingItem }
            item.list = shoppingList
            item.good = try self?.createOrGetGood(name: name, context: context)
            item.good?.personalRating = Int16(rating)
            item.quantity = Float(amount) ?? 1
            item.isWeight = isWeight
            item.price = Float(price) ?? 0
            item.isImportant = isImportant
            if !store.isEmpty {
                item.store = try self?.createOrGetStore(name: store, context: context)
            }
            try context.save()
        })
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
        return try await context.perform({[weak self] in
            guard !name.isEmpty, let shoppingitem = try context.existingObject(with: item.id) as? ShoppingListItem else { throw DBError.unableToGetShoppingItem }
            shoppingitem.good = try self?.createOrGetGood(name: name, context: context)
            shoppingitem.good?.personalRating = Int16(rating)
            shoppingitem.quantity = Float(amount) ?? 1
            shoppingitem.isWeight = isWeight
            shoppingitem.price = Float(price) ?? 0
            shoppingitem.isImportant = isImportant
            if !store.isEmpty {
                shoppingitem.store = try self?.createOrGetStore(name: store, context: context)
            }
            try context.save()
        })
    }
    
    private func createOrGetGood(name: String, context: NSManagedObjectContext) throws -> Good {
        let request = NSFetchRequest<Good>(entityName: "Good")
        request.predicate = NSPredicate(format: "name == %@", name)
        if let good = try context.fetch(request).first {
            return good
        }
        guard let good = NSEntityDescription.insertNewObject(forEntityName: "Good", into: context) as? Good else { throw DBError.unableToCreateGood }
        good.name = name
        return good
    }
    
    private func createOrGetStore(name: String, context: NSManagedObjectContext) throws -> Store {
        let request = NSFetchRequest<Store>(entityName: "Store")
        request.predicate = NSPredicate(format: "name == %@", name)
        if let store = try context.fetch(request).first {
            return store
        }
        guard let store = NSEntityDescription.insertNewObject(forEntityName: "Store", into: context) as? Store else { throw DBError.unableToCreateStore }
        store.name = name
        return store
    }
    
    func removeShoppingListItem(item: ShoppingListItemModel) async throws {
        let context = contextProvider.getContext()
        return try await context.perform({
            guard let shoppingItem = try context.existingObject(with: item.id) as? ShoppingListItem else { throw DBError.unableToGetShoppingItem }
            shoppingItem.isRemoved = true
            try context.save()
        })
    }
    
    func togglePurchasedShoppingListItem(item: ShoppingListItemModel) async throws {
        let context = contextProvider.getContext()
        return try await context.perform({
            guard let shoppingItem = try context.existingObject(with: item.id) as? ShoppingListItem else { throw DBError.unableToGetShoppingItem }
            shoppingItem.purchased = !shoppingItem.purchased
            try context.save()
        })
    }
    
    func getGoods() async throws -> [GoodsItemModel] {
        let context = contextProvider.getContext()
        return try await context.perform({
            let request = NSFetchRequest<Good>(entityName: "Good")
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            let items: [Good] = try context.fetch(request)
            return items.map({ good in
                GoodsItemModel(id: good.objectID, name: good.name ?? "", category: good.category?.name ?? "")
            })
        })
    }
    
    func addGood(name: String, category: String) async throws -> GoodsItemModel {
        let context = contextProvider.getContext()
        return try await context.perform({[weak self] in
            guard !name.isEmpty, let good = NSEntityDescription.insertNewObject(forEntityName: "Good", into: context) as? Good else { throw DBError.unableToCreateGood }
            good.name = name
            if !category.isEmpty {
                good.category = try self?.createOrGetCategory(name: category, context: context)
            }
            try context.save()
            return GoodsItemModel(id: good.objectID, name: good.name ?? "", category: good.category?.name ?? "")
        })
    }
    
    func editGood(item: GoodsItemModel, name: String, category: String) async throws -> GoodsItemModel {
        let context = contextProvider.getContext()
        return try await context.perform({[weak self] in
            guard !name.isEmpty, let good = try context.existingObject(with: item.id) as? Good else { throw DBError.unableToGetGood }
            good.name = name
            if !category.isEmpty {
                good.category = try self?.createOrGetCategory(name: category, context: context)
            } else {
                good.category = nil
            }
            try context.save()
            return GoodsItemModel(id: good.objectID, name: good.name ?? "", category: good.category?.name ?? "")
        })
    }
    
    private func createOrGetCategory(name: String, context: NSManagedObjectContext) throws -> Category {
        let request = NSFetchRequest<Category>(entityName: "Category")
        request.predicate = NSPredicate(format: "name == %@", name)
        if let category = try context.fetch(request).first {
            return category
        }
        guard let category = NSEntityDescription.insertNewObject(forEntityName: "Category", into: context) as? Category else { throw DBError.unableToCreateCategory }
        category.name = name
        return category
    }
    
    func removeGood(item: GoodsItemModel) async throws {
        let context = contextProvider.getContext()
        return try await context.perform({
            guard let good = try context.existingObject(with: item.id) as? Good else { throw DBError.unableToGetGood }
            let request = NSFetchRequest<ShoppingListItem>(entityName: "ShoppingListItem")
            request.predicate = NSPredicate(format: "good == %@", good)
            let items: [ShoppingListItem] = try context.fetch(request)
            for item in items {
                item.isRemoved = true
            }
            context.delete(good)
            try context.save()
        })
    }
    
    func getCategories() async throws -> [CategoriesItemModel] {
        let context = contextProvider.getContext()
        return try await context.perform({
            let request = NSFetchRequest<Category>(entityName: "Category")
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            let items: [Category] = try context.fetch(request)
            return items.filter({ $0.name?.isEmpty == false }).map({ category in
                CategoriesItemModel(id: category.objectID, name: category.name ?? "")
            })
        })
    }
    
    func addCategory(name: String) async throws -> CategoriesItemModel {
        let context = contextProvider.getContext()
        return try await context.perform({
            guard !name.isEmpty, let category = NSEntityDescription.insertNewObject(forEntityName: "Category", into: context) as? Category else { throw DBError.unableToCreateCategory }
            category.name = name
            try context.save()
            return CategoriesItemModel(id: category.objectID, name: category.name ?? "")
        })
    }
    
    func editCategory(item: CategoriesItemModel, name: String) async throws -> CategoriesItemModel {
        let context = contextProvider.getContext()
        return try await context.perform({
            guard !name.isEmpty, let category = try context.existingObject(with: item.id) as? Category else { throw DBError.unableToGetCategory }
            category.name = name
            try context.save()
            return CategoriesItemModel(id: category.objectID, name: category.name ?? "")
        })
    }
    
    func removeCategory(item: CategoriesItemModel) async throws {
        let context = contextProvider.getContext()
        return try await context.perform({
            guard let category = try context.existingObject(with: item.id) as? Category else { throw DBError.unableToGetCategory }
            context.delete(category)
            try context.save()
        })
    }
    
    func getStores() async throws -> [StoresItemModel] {
        let context = contextProvider.getContext()
        return try await context.perform({
            let request = NSFetchRequest<Store>(entityName: "Store")
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            let items: [Store] = try context.fetch(request)
            return items.filter({ $0.name?.isEmpty == false }).map({ store in
                StoresItemModel(id: store.objectID, name: store.name ?? "")
            })
        })
    }
    
    func addStore(name: String) async throws -> StoresItemModel {
        let context = contextProvider.getContext()
        return try await context.perform({
            guard !name.isEmpty, let store = NSEntityDescription.insertNewObject(forEntityName: "Store", into: context) as? Store else { throw DBError.unableToCreateStore }
            store.name = name
            try context.save()
            return StoresItemModel(id: store.objectID, name: store.name ?? "")
        })
    }
    
    func editStore(item: StoresItemModel, name: String) async throws -> StoresItemModel {
        let context = contextProvider.getContext()
        return try await context.perform({
            guard !name.isEmpty, let store = try context.existingObject(with: item.id) as? Store else { throw DBError.unableToGetStore }
            store.name = name
            try context.save()
            return StoresItemModel(id: store.objectID, name: store.name ?? "")
        })
    }
    
    func removeStore(item: StoresItemModel) async throws {
        let context = contextProvider.getContext()
        return try await context.perform({
            guard let store = try context.existingObject(with: item.id) as? Store else { throw DBError.unableToGetStore }
            context.delete(store)
            try context.save()
        })
    }
}

final class DAOStub: DAOProtocol, DIDependency {
    
    var shoppingLists: [ShoppingListModel] = [
        ShoppingListModel(id: NSManagedObjectID(), title: "test1"),
        ShoppingListModel(id: NSManagedObjectID(), title: "test2"),
        ShoppingListModel(id: NSManagedObjectID(), title: "test3"),
        ShoppingListModel(id: NSManagedObjectID(), title: "test4"),
        ShoppingListModel(id: NSManagedObjectID(), title: "test5"),
        ShoppingListModel(id: NSManagedObjectID(), title: "test6"),
        ShoppingListModel(id: NSManagedObjectID(), title: "test7")
    ]
    
    func getShoppingLists() async throws -> [ShoppingListModel] {
        return shoppingLists
    }
    
    func addShoppingList(name: String) async throws -> ShoppingListModel {
        return ShoppingListModel(id: NSManagedObjectID(), title: "test")
    }
    
    func removeShoppingList(_ item: ShoppingListModel) async throws {
    }
    
    var shoppingItems: [ShoppingListItemModel] = [
        ShoppingListItemModel(id: NSManagedObjectID(), title: "item title1", store: "store1", category: "category1", isPurchased: false, amount: "15", isWeight: false, price: "15", isImportant: false, rating: 5),
        ShoppingListItemModel(id: NSManagedObjectID(), title: "item title2", store: "store1", category: "category1", isPurchased: false, amount: "1", isWeight: false, price: "15", isImportant: false, rating: 5),
        ShoppingListItemModel(id: NSManagedObjectID(), title: "item title3", store: "store1", category: "category2", isPurchased: false, amount: "3", isWeight: false, price: "15", isImportant: false, rating: 5),
        ShoppingListItemModel(id: NSManagedObjectID(), title: "item title4", store: "store1", category: "category2", isPurchased: false, amount: "2", isWeight: false, price: "15", isImportant: false, rating: 5),
        ShoppingListItemModel(id: NSManagedObjectID(), title: "item title5", store: "store2", category: "category2", isPurchased: true, amount: "7", isWeight: false, price: "15", isImportant: false, rating: 5),
        ShoppingListItemModel(id: NSManagedObjectID(), title: "item title6", store: "store2", category: "category3", isPurchased: false, amount: "5", isWeight: false, price: "15", isImportant: false, rating: 5),
        ShoppingListItemModel(id: NSManagedObjectID(), title: "item title7", store: "store2", category: "category3", isPurchased: false, amount: "20", isWeight: false, price: "15", isImportant: false, rating: 5),
        ShoppingListItemModel(id: NSManagedObjectID(), title: "item title8", store: "store2", category: "category3", isPurchased: false, amount: "4", isWeight: false, price: "15", isImportant: false, rating: 5),
        ShoppingListItemModel(id: NSManagedObjectID(), title: "item title9", store: "store2", category: "category4", isPurchased: true, amount: "8", isWeight: false, price: "15", isImportant: false, rating: 5),
        ShoppingListItemModel(id: NSManagedObjectID(), title: "item title10", store: "store2", category: "category4", isPurchased: false, amount: "24", isWeight: false, price: "15", isImportant: false, rating: 5),
        ShoppingListItemModel(id: NSManagedObjectID(), title: "item title11", store: "store3", category: "category4", isPurchased: false, amount: "1", isWeight: false, price: "15", isImportant: false, rating: 5),
        ShoppingListItemModel(id: NSManagedObjectID(), title: "item title12", store: "store3", category: "category5", isPurchased: false, amount: "6", isWeight: false, price: "15", isImportant: false, rating: 5),
        ShoppingListItemModel(id: NSManagedObjectID(), title: "item title13", store: "store3", category: "category5", isPurchased: false, amount: "18", isWeight: false, price: "15", isImportant: false, rating: 5),
        ShoppingListItemModel(id: NSManagedObjectID(), title: "item title14", store: "store3", category: "category5", isPurchased: true, amount: "9", isWeight: false, price: "15", isImportant: false, rating: 5),
        ShoppingListItemModel(id: NSManagedObjectID(), title: "item title15", store: "store3", category: "category6", isPurchased: false, amount: "19", isWeight: false, price: "15", isImportant: false, rating: 5),
        ShoppingListItemModel(id: NSManagedObjectID(), title: "item title16", store: "store3", category: "category6", isPurchased: false, amount: "10", isWeight: false, price: "15", isImportant: false, rating: 5),
    ]
    
    func getShoppingListItems(list: ShoppingListModel) async throws -> [ShoppingListItemModel] {
        return shoppingItems
    }
    
    func addShoppingListItem(list: ShoppingListModel, name: String, amount: String, store: String, isWeight: Bool, price: String, isImportant: Bool, rating: Int) async throws {
    }
    
    func editShoppingListItem(item: ShoppingListItemModel, name: String, amount: String, store: String, isWeight: Bool, price: String, isImportant: Bool, rating: Int) async throws {        
    }
    
    func removeShoppingListItem(item: ShoppingListItemModel) async throws {
    }
    
    func togglePurchasedShoppingListItem(item: ShoppingListItemModel) async throws {
    }
    
    var goods: [GoodsItemModel] = [
        GoodsItemModel(id: NSManagedObjectID(), name: "Test good1", category: "Test category1"),
        GoodsItemModel(id: NSManagedObjectID(), name: "Test good2", category: "Test category1"),
        GoodsItemModel(id: NSManagedObjectID(), name: "Test good3", category: "Test category1"),
        GoodsItemModel(id: NSManagedObjectID(), name: "Test good4", category: "Test category2"),
        GoodsItemModel(id: NSManagedObjectID(), name: "Test good5", category: "Test category2"),
        GoodsItemModel(id: NSManagedObjectID(), name: "Test good6", category: "Test category2"),
        GoodsItemModel(id: NSManagedObjectID(), name: "Test good7", category: "Test category3"),
        GoodsItemModel(id: NSManagedObjectID(), name: "Test good8", category: "Test category3"),
        GoodsItemModel(id: NSManagedObjectID(), name: "Test good9", category: "Test category3")
    ]
    
    func getGoods() async throws -> [GoodsItemModel] {
        return goods
    }
    
    func addGood(name: String, category: String) async throws -> GoodsItemModel {
        return GoodsItemModel(id: NSManagedObjectID(), name: "Test good", category: "Test category")
    }
    
    func editGood(item: GoodsItemModel, name: String, category: String) async throws -> GoodsItemModel {
        return GoodsItemModel(id: NSManagedObjectID(), name: name, category: category)
    }
    
    func removeGood(item: GoodsItemModel) async throws {
    }
    
    var categories: [CategoriesItemModel] = [
        CategoriesItemModel(id: NSManagedObjectID(), name: "Test category 1"),
        CategoriesItemModel(id: NSManagedObjectID(), name: "Test category 2"),
        CategoriesItemModel(id: NSManagedObjectID(), name: "Test category 3"),
        CategoriesItemModel(id: NSManagedObjectID(), name: "Test category 4")
    ]
    
    func getCategories() async throws -> [CategoriesItemModel] {
        return categories
    }
    
    func addCategory(name: String) async throws -> CategoriesItemModel {
        return CategoriesItemModel(id: NSManagedObjectID(), name: "Test category")
    }
    
    func editCategory(item: CategoriesItemModel, name: String) async throws -> CategoriesItemModel {
        return CategoriesItemModel(id: NSManagedObjectID(), name: name)
    }
    
    func removeCategory(item: CategoriesItemModel) async throws {
    }
    
    var stores: [StoresItemModel] = [
        StoresItemModel(id: NSManagedObjectID(), name: "Test store 1"),
        StoresItemModel(id: NSManagedObjectID(), name: "Test store 2"),
        StoresItemModel(id: NSManagedObjectID(), name: "Test store 3"),
        StoresItemModel(id: NSManagedObjectID(), name: "Test store 4"),
        StoresItemModel(id: NSManagedObjectID(), name: "Test store 5"),
        StoresItemModel(id: NSManagedObjectID(), name: "Test store 6"),
        StoresItemModel(id: NSManagedObjectID(), name: "Test store 7"),
        StoresItemModel(id: NSManagedObjectID(), name: "Test store 8")
    ]
    
    func getStores() async throws -> [StoresItemModel] {
        return stores
    }
    
    func addStore(name: String) async throws -> StoresItemModel {
        return StoresItemModel(id: NSManagedObjectID(), name: "Test store")
    }
    
    func editStore(item: StoresItemModel, name: String) async throws -> StoresItemModel {
        return StoresItemModel(id: NSManagedObjectID(), name: name)
    }
    
    func removeStore(item: StoresItemModel) async throws {
    }
}
