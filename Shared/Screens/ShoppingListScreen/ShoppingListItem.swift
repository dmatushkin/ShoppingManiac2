//
//  ShoppingListItem.swift
//  ShoppingManiacUI
//
//  Created by Dmitry Matyushkin on 7/5/20.
//

import Foundation

enum ShoppingListItemAmount {
	private static let formatter: NumberFormatter = {
		let formatter = NumberFormatter()
		formatter.minimumFractionDigits = 1
		formatter.maximumFractionDigits = 2
		return formatter
	}()

	case quantity(value: Int)
	case weight(value: Double)

	var textValue: String {
		switch self {
		case .quantity(let value):
			return "\(value)"
		case .weight(let value):
			return ShoppingListItemAmount.formatter.string(from: NSNumber(floatLiteral: value)) ?? "\(value)"
		}
	}
}

struct ShoppingListItem: Identifiable {
	let id: Int
	let name: String
	let amount: ShoppingListItemAmount
	let isPurchased: Bool
}
