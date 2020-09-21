//
//  MainListItem.swift
//  ShoppingManiacUI
//
//  Created by Dmitry Matyushkin on 7/4/20.
//

import Foundation
import CoreData

struct MainListItem: Identifiable, Hashable {
	var id: NSManagedObjectID
	let name: String
	let isRemote: Bool
	let isCompleted: Bool
}
