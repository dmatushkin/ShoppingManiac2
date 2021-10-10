//
//  ContextProvider.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 10.10.2021.
//

import CoreData
import DependencyInjection

protocol ContextProviderProtocol {
    
    func getContext() -> NSManagedObjectContext
}

final class ContextProvider: ContextProviderProtocol, DIDependency {
    
    required init() {}
    
    func getContext() -> NSManagedObjectContext {
        return PersistenceController.shared.container.newBackgroundContext()
    }
}
