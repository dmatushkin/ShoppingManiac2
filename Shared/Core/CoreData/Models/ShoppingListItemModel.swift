//
//  ShoppingListItemModel.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 10.10.2021.
//

import Foundation
import CoreData

struct ShoppingListItemModel: Identifiable {
    let id: NSManagedObjectID
    let uniqueId: String
    let title: String
    let store: String
    let category: String
    let categoryStoreOrder: Int?
    let isPurchased: Bool
    let amount: String
    let isWeight: Bool
    let price: String
    let isImportant: Bool
    let rating: Int
    let recordId: String?
}
