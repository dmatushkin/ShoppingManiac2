//
//  ShoppingListCell.swift
//  ShoppingManiacUI
//
//  Created by Dmitry Matyushkin on 7/5/20.
//

import SwiftUI

struct ShoppingListCell: View {
	let isPurchased: Bool
	let name: String
	let amount: ShoppingListItemAmount

	var body: some View {
		HStack {
			Image(systemName: isPurchased ? "checkmark.square" : "square")
				.padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/, /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
			Text(name)
				.padding([.top, .bottom, .trailing], 10)
			Spacer(minLength: 0)
			Text(amount.textValue)
				.padding([.top, .bottom, .trailing], 10.0)
		}
	}
}

struct ShoppingListCell_Previews: PreviewProvider {
	static var previews: some View {
		Group {
			ShoppingListCell(isPurchased: false, name: "Bread", amount: .quantity(value: 5)).previewLayout(.sizeThatFits)
			ShoppingListCell(isPurchased: true, name: "Butter", amount: .weight(value: 7.5)).previewLayout(.sizeThatFits)
		}
	}
}
