//
//  Persistence.swift
//  Shared
//
//  Created by Dmitry Matyushkin on 12.06.2021.
//

import Foundation
import SwiftData

@MainActor
final class PersistenceController {
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
        let schema = ShoppingManiacSchema.current
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
            container = try ModelContainer(
                for: schema,
                migrationPlan: ShoppingManiacMigrationPlan.self,
                configurations: [configuration]
            )
        } catch {
            assertionFailure("Unable to initialize SwiftData container: \(error.localizedDescription)")
            do {
                let fallbackConfiguration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: true,
                    cloudKitDatabase: .none
                )
                container = try ModelContainer(
                    for: schema,
                    migrationPlan: ShoppingManiacMigrationPlan.self,
                    configurations: [fallbackConfiguration]
                )
            } catch {
                preconditionFailure("Unable to initialize fallback SwiftData container: \(error.localizedDescription)")
            }
        }
    }
}
