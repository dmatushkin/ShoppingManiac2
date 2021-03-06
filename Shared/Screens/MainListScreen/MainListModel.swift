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

	@Published var selectedItem: MainListItem?
	@Environment(\.previewMode) private var previewMode

	@Published fileprivate(set) var items: [MainListItem] = [
		MainListItem(id: NSManagedObjectID(), name: "Test 1", isRemote: true, isCompleted: false),
		MainListItem(id: NSManagedObjectID(), name: "Test 2", isRemote: false, isCompleted: false),
		MainListItem(id: NSManagedObjectID(), name: "Test 3", isRemote: false, isCompleted: true),
	]

	func addList(withTitle title: String) {
		let list = MainListItem(id: NSManagedObjectID(), name: title, isRemote: false, isCompleted: false)
		items.insert(list, at: 0)
		selectedItem = list
	}
}
