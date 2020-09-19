//
//  ShoppingListModel.swift
//  ShoppingManiacUI
//
//  Created by Dmitry Matyushkin on 7/5/20.
//

import Foundation
import SwiftUI

class ShoppingListModel: ObservableObject {

	@Environment(\.previewMode) private var previewMode

	@Published fileprivate(set) var sections: [ShoppingListSection] = [
		ShoppingListSection(id: 0, name: "Grocery store", items: [
			ShoppingListItem(id: 0, name: "Bread", amount: .quantity(value: 2), isPurchased: false),
			ShoppingListItem(id: 1, name: "Butter", amount: .weight(value: 1.5), isPurchased: true)
		]),
		ShoppingListSection(id: 1, name: "Laundry supply", items: [
			ShoppingListItem(id: 2, name: "Washing powder", amount: .weight(value: 3.0), isPurchased: false)
		])
	]

	func toggle(item: ShoppingListItem) {
		sections = sections.map({
			ShoppingListSection(id: $0.id,
								name: $0.name,
								items: $0.items.map({
									ShoppingListItem(id: $0.id,
													 name: $0.name,
													 amount: $0.amount,
													 isPurchased: $0.id == item.id ? !$0.isPurchased : $0.isPurchased)
								}))
		})
	}

	func move(item: ShoppingListItem, toSection section: ShoppingListSection) {
		sections = sections.map({
			ShoppingListSection(id: $0.id,
								name: $0.name,
								items: $0.id == section.id ?  ($0.items + [item]) : $0.items.filter({$0.id != item.id}))
		})
	}

	func delete(items: [ShoppingListItem], fromSection section: ShoppingListSection) {
		sections = sections.map({
			ShoppingListSection(id: $0.id,
								name: $0.name,
								items: $0.id == section.id ? $0.items.filter({ filtered in
																				!items.contains(where: { item in
																					item.id == filtered.id
																				})}) : $0.items)
		})
	}

	func delete(fromPath path: IndexPath) {
		let section = sections[path.section]
		let item = section.items[path.row]
		sections = sections.map({
			ShoppingListSection(id: $0.id,
								name: $0.name,
								items: $0.id == section.id ? $0.items.filter({ filtered in filtered.id != item.id }) : $0.items)
		})
	}
}
