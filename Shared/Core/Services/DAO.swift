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
    func deleteShoppingList(_ item: ShoppingListModel) async throws
    func getShoppingListItems(list: ShoppingListModel) async throws -> [ShoppingListItemModel]
    func addShoppingListItem(list: ShoppingListModel, name: String, amount: String) async throws
    func removeShoppingListItem(item: ShoppingListItemModel) async throws
    func togglePurchasedShoppingListItem(item: ShoppingListItemModel) async throws
    func getGoods() async throws -> [GoodsItemModel]
    func addGood(name: String, category: String) async throws -> GoodsItemModel
    func editGood(item: GoodsItemModel, name: String, category: String) async throws -> GoodsItemModel
    func getCategories() async throws -> [CategoriesItemModel]
    func addCategory(name: String) async throws -> CategoriesItemModel
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
    
    func deleteShoppingList(_ item: ShoppingListModel) async throws {
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
                                      amount: "\(item.quantity)")
            })
        })
    }
    
    func addShoppingListItem(list: ShoppingListModel, name: String, amount: String) async throws {
        let context = contextProvider.getContext()
        return try await context.perform({[weak self] in
            guard let shoppingList = try context.existingObject(with: list.id) as? ShoppingList else { throw DBError.unableToGetShoppingList }
            guard let item = NSEntityDescription.insertNewObject(forEntityName: "ShoppingListItem", into: context) as? ShoppingListItem else { throw DBError.unableToCreateShoppingItem }
            item.list = shoppingList
            item.good = try self?.createOrGetGood(name: name, context: context)
            item.quantity = Float(amount) ?? 1
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
}
