//
//  SwiftDataModels.swift
//  ShoppingManiac2
//
//  Created by Coding Assistant on 20.05.2026.
//

import Foundation
import SwiftData

@Model
final class ShoppingList {
    var id: String = UUID().uuidString
    var uniqueId: String = ""
    var name: String = ""
    var date: Date = Date()
    var isRemoved: Bool = false
    var ownerName: String?
    @Relationship(deleteRule: .nullify, inverse: \ShoppingListItem.list) var items: [ShoppingListItem]? = []
    
    init(id: String = UUID().uuidString, uniqueId: String = "", name: String = "", date: Date = Date(), isRemoved: Bool = false, ownerName: String? = nil) {
        self.id = id
        self.uniqueId = uniqueId
        self.name = name
        self.date = date
        self.isRemoved = isRemoved
        self.ownerName = ownerName
    }
}

@Model
final class ShoppingListItem {
    var id: String = UUID().uuidString
    var uniqueId: String = ""
    var comment: String?
    var isImportant: Bool = false
    var isRemoved: Bool = false
    var isWeight: Bool = false
    var price: Float = 0
    var purchased: Bool = false
    var purchaseDate: Date?
    var quantity: Float = 0
    var good: Good?
    var list: ShoppingList?
    var store: Store?
    
    init(id: String = UUID().uuidString, uniqueId: String = "") {
        self.id = id
        self.uniqueId = uniqueId
    }
}

@Model
final class Good {
    var id: String = UUID().uuidString
    var name: String = ""
    var personalRating: Int = 0
    var category: Category?
    @Relationship(deleteRule: .nullify, inverse: \ShoppingListItem.good) var items: [ShoppingListItem]? = []
    @Relationship(deleteRule: .cascade, inverse: \GoodRating.good) var ratings: [GoodRating]? = []
    @Relationship(deleteRule: .cascade, inverse: \Picture.good) var pictures: [Picture]? = []
    
    init(id: String = UUID().uuidString, name: String = "", personalRating: Int = 0, category: Category? = nil) {
        self.id = id
        self.name = name
        self.personalRating = personalRating
        self.category = category
    }
}

@Model
final class Category {
    var id: String = UUID().uuidString
    var name: String = ""
    var parent: Category?
    @Relationship(deleteRule: .nullify, inverse: \Category.parent) var children: [Category]? = []
    @Relationship(deleteRule: .nullify, inverse: \Good.category) var goods: [Good]? = []
    @Relationship(deleteRule: .cascade, inverse: \CategoryStoreOrder.category) var orders: [CategoryStoreOrder]? = []
    
    init(id: String = UUID().uuidString, name: String = "", parent: Category? = nil) {
        self.id = id
        self.name = name
        self.parent = parent
    }
}

@Model
final class Store {
    var id: String = UUID().uuidString
    var name: String = ""
    @Relationship(deleteRule: .nullify, inverse: \ShoppingListItem.store) var items: [ShoppingListItem]? = []
    @Relationship(deleteRule: .cascade, inverse: \CategoryStoreOrder.store) var orders: [CategoryStoreOrder]? = []
    
    init(id: String = UUID().uuidString, name: String = "") {
        self.id = id
        self.name = name
    }
}

@Model
final class CategoryStoreOrder {
    var id: String = UUID().uuidString
    var order: Int = 0
    var category: Category?
    var store: Store?
    
    init(id: String = UUID().uuidString, order: Int = 0, category: Category? = nil, store: Store? = nil) {
        self.id = id
        self.order = order
        self.category = category
        self.store = store
    }
}

@Model
final class GoodRating {
    var id: String = UUID().uuidString
    var date: Date?
    var rating: Int = 0
    var good: Good?
    
    init(id: String = UUID().uuidString, date: Date? = nil, rating: Int = 0, good: Good? = nil) {
        self.id = id
        self.date = date
        self.rating = rating
        self.good = good
    }
}

@Model
final class Picture {
    var id: String = UUID().uuidString
    @Attribute(.externalStorage) var image: Data?
    var shotDate: Date?
    var good: Good?
    
    init(id: String = UUID().uuidString, image: Data? = nil, shotDate: Date? = nil, good: Good? = nil) {
        self.id = id
        self.image = image
        self.shotDate = shotDate
        self.good = good
    }
}
