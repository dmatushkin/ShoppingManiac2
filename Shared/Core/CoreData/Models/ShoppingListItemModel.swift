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
    let title: String
    let store: String
    let category: String
}
