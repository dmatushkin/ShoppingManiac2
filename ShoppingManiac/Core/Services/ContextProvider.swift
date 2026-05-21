//
//  ContextProvider.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 10.10.2021.
//

import FactoryKit
import SwiftData

protocol ContextProviderProtocol: Sendable {
    func getContext() -> ModelContext
}

final class ContextProvider: ContextProviderProtocol, @unchecked Sendable {
    nonisolated required init() {}
    
    func getContext() -> ModelContext {
        ModelContext(PersistenceController.shared.container)
    }
}
