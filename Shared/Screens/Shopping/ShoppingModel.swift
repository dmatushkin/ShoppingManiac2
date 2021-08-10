//
//  ShoppingModel.swift
//  ShoppingModel
//
//  Created by Dmitry Matyushkin on 10.08.2021.
//

import SwiftUI
import Combine
import CoreData

final class ShoppingModel: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
    
    var objectWillChange = PassthroughSubject<Void, Never>()
    private let viewContext: NSManagedObjectContext
    var items: [ShoppingList] = []
    private var controller: NSFetchedResultsController<ShoppingList>!
    
    override init() {
        self.viewContext = PersistenceController.viewContext
        super.init()
        guard self.viewContext.persistentStoreCoordinator != nil else {
            print("No persistent store coordinator found")
            return
        }
        let fetchRequest = NSFetchRequest<ShoppingList>(entityName: "ShoppingList")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ShoppingList.date, ascending: false)]
        self.controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        self.controller.delegate = self
        try? self.controller.performFetch()
        self.items = self.controller.fetchedObjects ?? []
    }
        
    func addItem() {
        withAnimation {
            let newItem = ShoppingList(context: viewContext)
            newItem.date = Date().timeIntervalSinceReferenceDate

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.items = self.controller.fetchedObjects ?? []
        self.objectWillChange.send()
    }
}
