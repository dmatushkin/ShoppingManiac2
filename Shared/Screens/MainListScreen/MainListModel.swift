//
//  MainListModel.swift
//  ShoppingManiacUI
//
//  Created by Dmitry Matyushkin on 7/4/20.
//

import Foundation
import CoreData
import SwiftUI


class MainListModel: ObservableObject {

	@Published fileprivate(set) var items: [MainListItem] = [
		MainListItem(id: NSManagedObjectID(), name: "Test 1", isRemote: true, isCompleted: false),
		MainListItem(id: NSManagedObjectID(), name: "Test 2", isRemote: false, isCompleted: false),
		MainListItem(id: NSManagedObjectID(), name: "Test 3", isRemote: false, isCompleted: true),
	]
}

class MainListCoreDataModel: MainListModel {
	override init() {
		super.init()
		items = [
			MainListItem(id: NSManagedObjectID(), name: "Test 4", isRemote: true, isCompleted: false),
			MainListItem(id: NSManagedObjectID(), name: "Test 5", isRemote: false, isCompleted: false),
			MainListItem(id: NSManagedObjectID(), name: "Test 6", isRemote: false, isCompleted: true),
		]
	}
}
