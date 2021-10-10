//
//  DAO.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 10.10.2021.
//

import Foundation
import CoreData
import DependencyInjection

protocol DAOProtocol {
    func getShoppingLists() async throws -> [ShoppingListModel]
    func addShoppingList(name: String) async throws
    func deleteShoppingList(_ item: ShoppingListModel) async throws
}

final class DAO: DAOProtocol, DIDependency {
    
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
    
    func addShoppingList(name: String) async throws {
        let context = contextProvider.getContext()
        return try await context.perform({
            guard let item = NSEntityDescription.insertNewObject(forEntityName: "ShoppingList", into: context) as? ShoppingList else { return }
            item.name = name
            item.date = Date().timeIntervalSinceReferenceDate
            try context.save()
        })
    }
    
    func deleteShoppingList(_ item: ShoppingListModel) async throws {
        let context = contextProvider.getContext()
        return try await context.perform({
            if let item = try? context.existingObject(with: item.id) as? ShoppingList {
                item.isRemoved = true
                try context.save()
            }
        })
    }
}
