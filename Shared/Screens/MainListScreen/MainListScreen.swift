//
//  MainListScreen.swift
//  ShoppingManiacUI
//
//  Created by Dmitry Matyushkin on 7/4/20.
//

import SwiftUI

struct MainListScreen: View {
	@StateObject private var model = MainListModel()
	@State private var selectedItem: MainListItem?
	@State private var showAddListPanel = false
	@State private var listToAddName: String = ""

	var body: some View {
		NavigationView {
			List(model.items) { item in
				NavigationLink(
					destination: ShoppingListScreen(mainListItem: item),
					tag: item,
					selection: $selectedItem,
					label: {
						MainListCell(listName: item.name, isCompleted: item.isCompleted, isRemote: item.isRemote)
					})
			}.listStyle(PlainListStyle())
			.navigationTitle(Text("Shopping Lists"))
			.navigationBarItems(trailing:
									Button(action: {
										listToAddName = ""
										showAddListPanel = true
									}, label: {
										Image(systemName: "doc.badge.plus").imageScale(.large)
									}).sheet(isPresented: $showAddListPanel, content: {
										AddShoppingListScreen(listToAddName: $listToAddName, showAddListPanel: $showAddListPanel, selectedItem: $selectedItem, model: model)
									})
			)
			VStack {
				Text("Shopping list not selected")
			}.navigationTitle(Text("List"))
		}
	}
}

struct MainListScreen_Previews: PreviewProvider {

	static var previews: some View {
		MainListScreen()
	}
}
