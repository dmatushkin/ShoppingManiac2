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
	@Binding var selectedItem: MainListItem?
	let model: MainListModel

	var body: some View {
		VStack {
			TextField("Shopping list name", text: $listToAddName).padding().overlay(
				RoundedRectangle(cornerRadius: 5).stroke(Color.black, lineWidth: 1)
			).padding([.top, .leading, .trailing])
			HStack {
				Button(action: {
					showAddListPanel = false
				}, label: {
					Text("Cancel").foregroundColor(.white)
				}).frame(idealWidth: .infinity, maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, minHeight: 50, idealHeight: 50, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/).background(Color.red).cornerRadius(5)
				Button(action: {
					showAddListPanel = false
					selectedItem = model.addList(withTitle: listToAddName)
				}, label: {
					Text("Save").foregroundColor(.white)
				}).frame(idealWidth: .infinity, maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, minHeight: 50, idealHeight: 50, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/).background(Color.green).cornerRadius(5)
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
		AddShoppingListScreen(listToAddName: $listToAddName, showAddListPanel: $showAddListPanel, selectedItem: $selectedItem, model: model)
    }
}
