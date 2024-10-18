//
//  Factory.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 10/18/24.
//

import Factory

extension Container {
    var contextProvider: Factory<ContextProviderProtocol> {
        Factory(self) { ContextProvider() }.singleton
    }

    var dao: Factory<DAOProtocol> {
        Factory(self) { DAO() }.singleton
    }

    var shoppingListSerializer: Factory<ShoppingListSerializerProtocol> {
        Factory(self) { ShoppingListSerializer() }.singleton
    }
}
