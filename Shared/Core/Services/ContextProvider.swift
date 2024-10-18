//
//  ContextProvider.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 10.10.2021.
//

import CoreData
import Factory

protocol ContextProviderProtocol: Sendable {
    
    func getContext() -> NSManagedObjectContext
}

final class ContextProvider: ContextProviderProtocol {
    
    required init() {}
    
    func getContext() -> NSManagedObjectContext {
        return PersistenceController.shared.container.newBackgroundContext()
    }
}
