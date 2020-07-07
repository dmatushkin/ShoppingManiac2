//
//  ShoppingListSection.swift
//  ShoppingManiacUI
//
//  Created by Dmitry Matyushkin on 7/5/20.
//

import Foundation

struct ShoppingListSection: Identifiable {
	let id: Int
	let name: String?
	let items: [ShoppingListItem]
}
