//
//  Persistence.swift
//  Shared
//
//  Created by Dmitry Matyushkin on 12.06.2021.
//

import Foundation
import SwiftData

final class PersistenceController: @unchecked Sendable {
    static let shared = PersistenceController(
        inMemory: ProcessInfo.processInfo.arguments.contains("-UITestInMemoryStore")
    )
    
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let context = ModelContext(result.container)
        for _ in 0..<10 {
            context.insert(ShoppingList(date: Date()))
        }
        try? context.save()
        return result
    }()
    
    let container: ModelContainer
    
    init(inMemory: Bool = false) {
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
        let configuration: ModelConfiguration
        if inMemory {
            configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true,
                cloudKitDatabase: .none
            )
        } else {
            let storesURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let storeURL = storesURL.appendingPathComponent("ShoppingManiac.sqlite")
            configuration = ModelConfiguration(
                schema: schema,
                url: storeURL,
                cloudKitDatabase: .automatic
            )
        }
        
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Unable to initialize SwiftData container: \(error.localizedDescription)")
        }
    }
}
