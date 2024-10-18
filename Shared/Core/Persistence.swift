//
//  Persistence.swift
//  Shared
//
//  Created by Dmitry Matyushkin on 12.06.2021.
//

import CoreData
import CloudKit

final class PersistenceController: @unchecked Sendable {

    static var viewContext: NSManagedObjectContext {
        return shared.container.viewContext
    }
    
    static let shared = PersistenceController()
    
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<10 {
            let newItem = ShoppingList(context: viewContext)
            let date = Date()
            newItem.date = date.timeIntervalSinceReferenceDate
        }
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()
    
    let container: NSPersistentCloudKitContainer
        
    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "ShoppingManiac")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            guard let privateStoreDescription = container.persistentStoreDescriptions.first else {
                fatalError("Unable to get persistentStoreDescription")
            }
            let storesURL = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: .userDomainMask).first
            privateStoreDescription.url = storesURL?.appendingPathComponent("ShoppingManiac.sqlite")
            let sharedStoreURL = storesURL?.appendingPathComponent("shared.sqlite")
            guard let sharedStoreDescription = privateStoreDescription.copy() as? NSPersistentStoreDescription else {
                fatalError("Copying the private store description returned an unexpected value.")
            }
            sharedStoreDescription.url = sharedStoreURL
            
            guard let containerIdentifier = privateStoreDescription.cloudKitContainerOptions?.containerIdentifier else {
                fatalError("Unable to get containerIdentifier")
            }
            let sharedStoreOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: containerIdentifier)
            sharedStoreOptions.databaseScope = .shared
            sharedStoreDescription.cloudKitContainerOptions = sharedStoreOptions
            container.persistentStoreDescriptions.append(sharedStoreDescription)
        }
        container.loadPersistentStores(completionHandler: {[weak self] (storeDescription, error) in
            guard let self = self else { return }
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            } else if let cloudKitContainerOptions = storeDescription.cloudKitContainerOptions,
                      let loadedStoreDescritionURL = storeDescription.url {
                if cloudKitContainerOptions.databaseScope == .private {
                    let privateStore = self.container.persistentStoreCoordinator.persistentStore(for: loadedStoreDescritionURL)
                    self.privatePersistentStore = privateStore
                } else if cloudKitContainerOptions.databaseScope == .shared {
                    let sharedStore = self.container.persistentStoreCoordinator.persistentStore(for: loadedStoreDescritionURL)
                    self.sharedPersistentStore = sharedStore
                }
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        //container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(managedObjectContextObjectsDidChange),
                         name: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
                         object: container.viewContext)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func managedObjectContextObjectsDidChange(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        
        let changes = (userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject> ?? [])
            .union((userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject> ?? []))
            .union((userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject> ?? []))
        
        if changes.contains(where: { $0 is ShoppingList }) {
            GlobalCommands.reloadTopList.send()
        }
    }
        
    var privatePersistentStore: NSPersistentStore?
    var sharedPersistentStore: NSPersistentStore?
    
    var ckContainer: CKContainer? {
        guard let identifier = container.persistentStoreDescriptions.first?.cloudKitContainerOptions?.containerIdentifier else {
            return nil
        }
        return CKContainer(identifier: identifier)
    }
    
    func getShare(_ list: ShoppingListModel) async throws -> CKShare? {
        let shareDictionary = try container.fetchShares(matching: [list.id])
        if let share = shareDictionary[list.id] {
            share[CKShare.SystemFieldKey.title] = list.title
            return share
        }
        let item = try container.viewContext.existingObject(with: list.id)
        let (_, share, _) = try await container.share([item], to: nil)
        share[CKShare.SystemFieldKey.title] = list.title
        return share
    }
}
