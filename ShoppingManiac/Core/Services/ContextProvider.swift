//
//  ContextProvider.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 10.10.2021.
//

import FactoryKit
import SwiftData

@MainActor
protocol ContextProviderProtocol {
    func getContext() -> ModelContext
}

@MainActor
final class ContextProvider: ContextProviderProtocol {
    nonisolated required init() {}
    
    func getContext() -> ModelContext {
        ModelContext(PersistenceController.shared.container)
    }
}
