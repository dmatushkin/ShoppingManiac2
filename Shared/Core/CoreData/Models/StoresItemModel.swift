//
//  StoresItemModel.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 27.10.2021.
//

import Foundation
import CoreData

struct StoresItemModel: Identifiable, Hashable {
    let id: NSManagedObjectID
    let name: String
}
