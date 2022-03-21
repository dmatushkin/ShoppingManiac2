//
//  ShoppingListModel.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 10.10.2021.
//

import Foundation
import CoreData

struct ShoppingListModel: Identifiable, Hashable {
    
    private static let formatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        return dateFormatter
    }()
    
    let id: NSManagedObjectID
    let uniqueId: String
    let name: String
    let date: Date
    let recordId: String?
    
    var title: String {
        return name.isEmpty ? ShoppingListModel.formatter.string(from: date) : name
    }
}
