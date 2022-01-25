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
    func addShoppingList(name: String, date: Date) async throws -> ShoppingListModel
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
        case unableToCreateOder
        case unableToGetOrder
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
                let date = Date(timeIntervalSinceReferenceDate: list.date)
                let name = list.name ?? ""
                return ShoppingListModel(id: list.objectID, name: name, date: date)
            })
        })
    }
    
    func addShoppingList(name: String, date: Date) async throws -> ShoppingListModel {
        let context = contextProvider.getContext()
        return try await context.perform({
            guard let item = NSEntityDescription.insertNewObject(forEntityName: "ShoppingList", into: context) as? ShoppingList else { throw DBError.unableToCreateShoppingList }
            item.name = name
            item.date = date.timeIntervalSinceReferenceDate
            try context.save()
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            let date = Date(timeIntervalSinceReferenceDate: item.date)
            let name = item.name ?? ""
            return ShoppingListModel(id: item.objectID, name: name, date: date)
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
                let orders: [CategoryStoreOrder] = item.good?.category?.orders.getArray() ?? []
                let order = (orders.first(where: { $0.store?.objectID == item.store?.objectID })?.order).map({ Int($0) })
                return ShoppingListItemModel(id: item.objectID,
                                      title: item.good?.name ?? "",
                                      store: item.store?.name ?? "",
                                      category: item.good?.category?.name ?? "",
                                      categoryStoreOrder: order,
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
        
    func getGoods(search: String) async throws -> [GoodsItemModel] {
        let context = contextProvider.getContext()
        return try await context.perform({
            let request = NSFetchRequest<Good>(entityName: "Good")
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            if !search.isEmpty {
                request.predicate = NSPredicate(format: "name CONTAINS[cd] %@", search)
            }
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
        
    func getCategories(search: String) async throws -> [CategoriesItemModel] {
        let context = contextProvider.getContext()
        return try await context.perform({
            let request = NSFetchRequest<Category>(entityName: "Category")
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            if !search.isEmpty {
                request.predicate = NSPredicate(format: "name CONTAINS[cd] %@", search)
            }
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
    
    func getCategoryGoods(item: CategoriesItemModel) async throws -> [GoodsItemModel] {
        let context = contextProvider.getContext()
        return try await context.perform({
            guard let category = try context.existingObject(with: item.id) as? Category else { throw DBError.unableToGetCategory }
            
            let items: [Good] = category.goods.getArray().sorted(by: { ($0.name ?? "") < ($1.name ?? "") })
            return items.map({ good in
                GoodsItemModel(id: good.objectID, name: good.name ?? "", category: good.category?.name ?? "")
            })
        })
    }
    
    func syncCategoryGoods(item: CategoriesItemModel, goods: [String]) async throws {
        let context = contextProvider.getContext()
        return try await context.perform({ [weak self] in
            guard let self = self, let category = try context.existingObject(with: item.id) as? Category else { throw DBError.unableToGetCategory }
            let goods = try goods.map({ try self.createOrGetGood(name: $0, context: context) })
            category.goods = NSSet(array: goods)
            try context.save()
        })
    }
    
    func getStores(search: String) async throws -> [StoresItemModel] {
        let context = contextProvider.getContext()
        return try await context.perform({
            let request = NSFetchRequest<Store>(entityName: "Store")
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            if !search.isEmpty {
                request.predicate = NSPredicate(format: "name CONTAINS[cd] %@", search)
            }
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
    
    func getStoreCategories(item: StoresItemModel) async throws -> [CategoriesItemModel] {
        let context = contextProvider.getContext()
        return try await context.perform({
            guard let store = try context.existingObject(with: item.id) as? Store else { throw DBError.unableToGetStore }
            let orders: [CategoryStoreOrder] = store.orders.getArray().sorted(by: { $0.order < $1.order })
            return orders.compactMap({ $0.category }).map({ category in
                CategoriesItemModel(id: category.objectID, name: category.name ?? "")
            })
        })
    }
    
    func syncStoreCategories(item: StoresItemModel, categories: [String]) async throws {
        let context = contextProvider.getContext()
        return try await context.perform({[weak self] in
            guard let self = self, let store = try context.existingObject(with: item.id) as? Store else { throw DBError.unableToGetStore }
            let categories = try categories.map({ try self.createOrGetCategory(name: $0, context: context) })
            let ordersToRemove: [CategoryStoreOrder] = store.orders.getArray().filter({ !($0.category.map({category in categories.contains(category)}) ?? false) })
            for order in ordersToRemove {
                context.delete(order)
            }
            let orderedCategories = (store.orders.getArray() as [CategoryStoreOrder]).compactMap({ $0.category })
            for category in categories.filter({ !orderedCategories.contains($0) }) {
                if let order = NSEntityDescription.insertNewObject(forEntityName: "CategoryStoreOrder", into: context) as? CategoryStoreOrder {
                    order.category = category
                    order.store = store
                } else {
                    throw DBError.unableToCreateOder
                }
            }
            let allOrders: [CategoryStoreOrder] = store.orders.getArray()
            for (idx, category) in categories.enumerated() {
                if let order = allOrders.first(where: { $0.category == category }) {
                    order.order = Int64(idx)
                } else {
                    throw DBError.unableToGetOrder
                }
            }
            try context.save()
        })
    }
}

final class DAOStub: DAOProtocol, DIDependency {
    
    var shoppingLists: [ShoppingListModel] = [
        ShoppingListModel(id: NSManagedObjectID(), name: "test1", date: Date()),
        ShoppingListModel(id: NSManagedObjectID(), name: "test2", date: Date()),
        ShoppingListModel(id: NSManagedObjectID(), name: "test3", date: Date()),
        ShoppingListModel(id: NSManagedObjectID(), name: "test4", date: Date()),
        ShoppingListModel(id: NSManagedObjectID(), name: "test5", date: Date()),
        ShoppingListModel(id: NSManagedObjectID(), name: "test6", date: Date()),
        ShoppingListModel(id: NSManagedObjectID(), name: "test7", date: Date())
    ]
    
    func getShoppingLists() async throws -> [ShoppingListModel] {
        return shoppingLists
    }
    
    func addShoppingList(name: String, date: Date) async throws -> ShoppingListModel {
        return ShoppingListModel(id: NSManagedObjectID(), name: "test", date: date)
    }
    
    func removeShoppingList(_ item: ShoppingListModel) async throws {
    }
    
    var shoppingItems: [ShoppingListItemModel] = [
        ShoppingListItemModel(id: NSManagedObjectID(), title: "item title1", store: "store1", category: "category1", categoryStoreOrder: 0, isPurchased: false, amount: "15", isWeight: false, price: "15", isImportant: false, rating: 5),
        ShoppingListItemModel(id: NSManagedObjectID(), title: "item title2", store: "store1", category: "category1", categoryStoreOrder: 0, isPurchased: false, amount: "1", isWeight: false, price: "15", isImportant: false, rating: 5),
        ShoppingListItemModel(id: NSManagedObjectID(), title: "item title3", store: "store1", category: "category2", categoryStoreOrder: 0, isPurchased: true, amount: "3", isWeight: false, price: "15", isImportant: false, rating: 5),
        ShoppingListItemModel(id: NSManagedObjectID(), title: "item title4", store: "store1", category: "category2", categoryStoreOrder: 0, isPurchased: false, amount: "2", isWeight: false, price: "15", isImportant: false, rating: 5),
        ShoppingListItemModel(id: NSManagedObjectID(), title: "item title5", store: "store2", category: "category2", categoryStoreOrder: 0, isPurchased: true, amount: "7", isWeight: false, price: "15", isImportant: false, rating: 5),
        ShoppingListItemModel(id: NSManagedObjectID(), title: "item title6", store: "store2", category: "category3", categoryStoreOrder: 0, isPurchased: false, amount: "5", isWeight: false, price: "15", isImportant: false, rating: 5),
        ShoppingListItemModel(id: NSManagedObjectID(), title: "item title7", store: "store2", category: "category3", categoryStoreOrder: 0, isPurchased: false, amount: "20", isWeight: false, price: "15", isImportant: false, rating: 5),
        ShoppingListItemModel(id: NSManagedObjectID(), title: "item title8", store: "store2", category: "category3", categoryStoreOrder: 0, isPurchased: false, amount: "4", isWeight: false, price: "15", isImportant: false, rating: 5),
        ShoppingListItemModel(id: NSManagedObjectID(), title: "item title9", store: "store2", category: "category4", categoryStoreOrder: 0, isPurchased: true, amount: "8", isWeight: false, price: "15", isImportant: false, rating: 5),
        ShoppingListItemModel(id: NSManagedObjectID(), title: "item title10", store: "store2", category: "category4", categoryStoreOrder: 0, isPurchased: false, amount: "24", isWeight: false, price: "15", isImportant: false, rating: 5),
        ShoppingListItemModel(id: NSManagedObjectID(), title: "item title11", store: "store3", category: "category4", categoryStoreOrder: 0, isPurchased: false, amount: "1", isWeight: false, price: "15", isImportant: false, rating: 5),
        ShoppingListItemModel(id: NSManagedObjectID(), title: "item title12", store: "store3", category: "category5", categoryStoreOrder: 0, isPurchased: false, amount: "6", isWeight: false, price: "15", isImportant: false, rating: 5),
        ShoppingListItemModel(id: NSManagedObjectID(), title: "item title13", store: "store3", category: "category5", categoryStoreOrder: 0, isPurchased: false, amount: "18", isWeight: false, price: "15", isImportant: false, rating: 5),
        ShoppingListItemModel(id: NSManagedObjectID(), title: "item title14", store: "store3", category: "category5", categoryStoreOrder: 0, isPurchased: true, amount: "9", isWeight: false, price: "15", isImportant: false, rating: 5),
        ShoppingListItemModel(id: NSManagedObjectID(), title: "item title15", store: "store3", category: "category6", categoryStoreOrder: 0, isPurchased: false, amount: "19", isWeight: false, price: "15", isImportant: false, rating: 5),
        ShoppingListItemModel(id: NSManagedObjectID(), title: "item title16", store: "store3", category: "category6", categoryStoreOrder: 0, isPurchased: false, amount: "10", isWeight: false, price: "15", isImportant: false, rating: 5),
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
    
    func getGoods(search: String) async throws -> [GoodsItemModel] {
        guard !search.isEmpty else { return goods }
        return goods.filter({ $0.name.lowercased().contains(search.lowercased())})
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
        
    func getCategories(search: String) async throws -> [CategoriesItemModel] {
        guard !search.isEmpty else { return categories }
        return categories.filter({ $0.name.lowercased().contains(search.lowercased())})
    }
    
    func addCategory(name: String) async throws -> CategoriesItemModel {
        return CategoriesItemModel(id: NSManagedObjectID(), name: "Test category")
    }
    
    func editCategory(item: CategoriesItemModel, name: String) async throws -> CategoriesItemModel {
        return CategoriesItemModel(id: NSManagedObjectID(), name: name)
    }
    
    func removeCategory(item: CategoriesItemModel) async throws {
    }
    
    func getCategoryGoods(item: CategoriesItemModel) async throws -> [GoodsItemModel] {
        return []
    }
    
    func syncCategoryGoods(item: CategoriesItemModel, goods: [String]) async throws {
        
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
    
    func getStores(search: String) async throws -> [StoresItemModel] {
        guard !search.isEmpty else { return stores }
        return stores.filter({ $0.name.lowercased().contains(search.lowercased()) })
    }
    
    func addStore(name: String) async throws -> StoresItemModel {
        return StoresItemModel(id: NSManagedObjectID(), name: "Test store")
    }
    
    func editStore(item: StoresItemModel, name: String) async throws -> StoresItemModel {
        return StoresItemModel(id: NSManagedObjectID(), name: name)
    }
    
    func removeStore(item: StoresItemModel) async throws {
    }
    
    func getStoreCategories(item: StoresItemModel) async throws -> [CategoriesItemModel] {
        return []
    }
    
    func syncStoreCategories(item: StoresItemModel, categories: [String]) async throws {        
    }
}
