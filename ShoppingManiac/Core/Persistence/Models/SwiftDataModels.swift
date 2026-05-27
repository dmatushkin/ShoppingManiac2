//
//  SwiftDataModels.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 20.05.2026.
//

import Foundation
import SwiftData

@Model
final class ShoppingList {
    var name: String = ""
    var date: Date = Date()
    var isRemoved: Bool = false
    @Relationship(deleteRule: .nullify, inverse: \ShoppingListItem.list) var items: [ShoppingListItem]? = []
    
    init(name: String = "", date: Date = Date(), isRemoved: Bool = false) {
        self.name = name
        self.date = date
        self.isRemoved = isRemoved
    }
}

@Model
final class ShoppingListItem {
    var isImportant: Bool = false
    var isRemoved: Bool = false
    var isWeight: Bool = false
    var price: Decimal = 0
    var purchased: Bool = false
    var quantity: Decimal = 0
    var rating: Int = 0
    var good: Good?
    var list: ShoppingList?
    var store: Store?
    
    init() {}
}

@Model
final class Good {
    var name: String = ""
    var canonicalName: String = ""
    var isRemoved: Bool = false
    var category: Category?
    @Relationship(deleteRule: .nullify, inverse: \ShoppingListItem.good) var items: [ShoppingListItem]? = []
    
    init(name: String = "", isRemoved: Bool = false, category: Category? = nil) {
        self.name = name
        self.canonicalName = name.shoppingCanonicalName
        self.isRemoved = isRemoved
        self.category = category
    }
}

@Model
final class Category {
    var name: String = ""
    var canonicalName: String = ""
    var isRemoved: Bool = false
    @Relationship(deleteRule: .nullify, inverse: \Good.category) var goods: [Good]? = []
    @Relationship(deleteRule: .cascade, inverse: \CategoryStoreOrder.category) var orders: [CategoryStoreOrder]? = []
    
    init(name: String = "", isRemoved: Bool = false) {
        self.name = name
        self.canonicalName = name.shoppingCanonicalName
        self.isRemoved = isRemoved
    }
}

@Model
final class Store {
    var name: String = ""
    var canonicalName: String = ""
    var isRemoved: Bool = false
    @Relationship(deleteRule: .nullify, inverse: \ShoppingListItem.store) var items: [ShoppingListItem]? = []
    @Relationship(deleteRule: .cascade, inverse: \CategoryStoreOrder.store) var orders: [CategoryStoreOrder]? = []
    
    init(name: String = "", isRemoved: Bool = false) {
        self.name = name
        self.canonicalName = name.shoppingCanonicalName
        self.isRemoved = isRemoved
    }
}

@Model
final class CategoryStoreOrder {
    var order: Int = 0
    var category: Category?
    var store: Store?
    
    init(order: Int = 0, category: Category? = nil, store: Store? = nil) {
        self.order = order
        self.category = category
        self.store = store
    }
}
