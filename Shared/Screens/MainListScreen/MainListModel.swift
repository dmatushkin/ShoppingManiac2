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

	@Environment(\.previewMode) private var previewMode

	@Published fileprivate(set) var items: [MainListItem] = [
		MainListItem(id: NSManagedObjectID(), name: "Test 1", isRemote: true, isCompleted: false),
		MainListItem(id: NSManagedObjectID(), name: "Test 2", isRemote: false, isCompleted: false),
		MainListItem(id: NSManagedObjectID(), name: "Test 3", isRemote: false, isCompleted: true),
	]
}
