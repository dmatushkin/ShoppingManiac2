//
//  ShoppingListItemView.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 27.10.2021.
//

import SwiftUI

struct ShoppingListItemView: View {
    
    private let item: ShoppingListItemModel
    
    init(item: ShoppingListItemModel) {
        self.item = item
    }
    
    var body: some View {
        HStack {
            Image(systemName: item.isPurchased ? "checkmark.square" : "square").padding([.top, .bottom], 8)
            Text(item.title).padding([.top, .bottom], 8)
            Spacer()
            Text(item.amount)
        }.contentShape(Rectangle())
    }
}
