//
//  ShoppingListScreen.swift
//  ShoppingManiacUI
//
//  Created by Dmitry Matyushkin on 7/5/20.
//

import SwiftUI

struct ShoppingListScreen: View {
	@ObservedObject
	var shoppingListModel: ShoppingListModel
	@State
	private var editMode = EditMode.inactive

	init() {
		shoppingListModel = ShoppingListModel()
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
					}
				}
			}
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
        ShoppingListScreen()
    }
}
