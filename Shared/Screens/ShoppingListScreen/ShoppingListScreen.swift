//
//  ShoppingListScreen.swift
//  ShoppingManiacUI
//
//  Created by Dmitry Matyushkin on 7/5/20.
//

import SwiftUI
import CoreData

struct ShoppingListScreen: View {
	@ObservedObject
	var shoppingListModel: ShoppingListModel
	@State
	private var editMode = EditMode.inactive

	init(mainListItem: MainListItem) {
		shoppingListModel = ShoppingListModel(mainListItem: mainListItem)
	}
	
    var body: some View {
		List {
			ForEach(shoppingListModel.sections) { section in
				Section(header: Text(section.name ?? "")) {
					ForEach(section.items) { item in
						ShoppingListCell(isPurchased: item.isPurchased, name: item.name, amount: item.amount)
							.onTapGesture {
								shoppingListModel.toggle(item: item)
							}
					}.onDelete { indexSet in
					}.onMove(perform: {from, to in
						shoppingListModel.move(from: from, toRow: to, fromSection: section)
						print("from \(from) to \(to)")
					})
				}
			}.onMove(perform: {from, to in
				print("from \(from) to \(to)")
			})
		}.swipeActions(editAction: {path in

		}, deleteAction: {path in
			shoppingListModel.delete(fromPath: path)
		}).listStyle(SidebarListStyle())
		.navigationTitle(Text("Shopping List"))
		.navigationBarItems(trailing: EditButton())
		.environment(\.editMode, $editMode)
    }
}

struct ShoppingListScreen_Previews: PreviewProvider {
    static var previews: some View {
        ShoppingListScreen(mainListItem: MainListItem(id: NSManagedObjectID(), name: "test", isRemote: false, isCompleted: false))
    }
}
