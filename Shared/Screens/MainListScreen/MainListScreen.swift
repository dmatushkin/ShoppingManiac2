//
//  MainListScreen.swift
//  ShoppingManiacUI
//
//  Created by Dmitry Matyushkin on 7/4/20.
//

import SwiftUI

struct MainListScreen: View {
	@EnvironmentObject private var model: MainListModel

	var body: some View {
		NavigationView {
			List(model.items) { item in
				NavigationLink(
					destination: ShoppingListScreen(),
					label: {
						MainListCell(listName: item.name, isCompleted: item.isCompleted, isRemote: item.isRemote)
					})
			}.listStyle(PlainListStyle())
			.navigationTitle(Text("Shopping Lists"))
			.navigationBarItems(trailing:
									Button(action: {}, label: {
										Image(systemName: "doc.badge.plus").imageScale(.large)
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
		MainListScreen().environmentObject(MainListModel())
	}
}
