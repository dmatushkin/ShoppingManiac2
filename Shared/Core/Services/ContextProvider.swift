//
//  ContextProvider.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 10.10.2021.
//

import Factory
import SwiftData

protocol ContextProviderProtocol: Sendable {
    func getContext() -> ModelContext
}

final class ContextProvider: ContextProviderProtocol, @unchecked Sendable {
    required init() {}
    
    func getContext() -> ModelContext {
        ModelContext(PersistenceController.shared.container)
    }
}
