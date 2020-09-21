//
//  AddShoppingListScreen.swift
//  ShoppingManiacUI
//
//  Created by Dmitry Matyushkin on 9/21/20.
//

import SwiftUI



struct AddShoppingListScreen: View {
	@Binding var listToAddName: String
	@Binding var showAddListPanel: Bool
	let model: MainListModel

	var body: some View {
		VStack {
			TextField("Shopping list name", text: $listToAddName).commonInput().padding([.top, .leading, .trailing])
			HStack {
				Button(action: {
					showAddListPanel = false
				}, label: {
					Text("Cancel")
				}).commonButton(success: false)
				Button(action: {
					showAddListPanel = false
					model.addList(withTitle: listToAddName)
				}, label: {
					Text("Save")
				}).commonButton(success: true)
			}.padding()
			Spacer()
		}
	}
}

struct AddShoppingListScreen_Previews: PreviewProvider {
	@StateObject private static var model = MainListModel()
	@State private static var selectedItem: MainListItem?
	@State private static var showAddListPanel = false
	@State private static var listToAddName: String = ""
    static var previews: some View {
		AddShoppingListScreen(listToAddName: $listToAddName, showAddListPanel: $showAddListPanel, model: model)
    }
}
