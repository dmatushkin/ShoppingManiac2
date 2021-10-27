//
//  AddShoppingListItemView.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 27.10.2021.
//

import SwiftUI

struct AddShoppingListItemView: View {
    
    @State private var itemName: String = ""
    @State private var amount: String = ""
    let model: ShoppingListViewModel
    
    init(model: ShoppingListViewModel) {
        self.model = model
    }
    
    var body: some View {
        VStack {
            TextField("Item name", text: $itemName).textFieldStyle(.roundedBorder)
            TextField("Amount", text: $amount).textFieldStyle(.roundedBorder)
            Button("Add", action: {
                Task {
                    try await model.addShoppingListItem(name: itemName, amount: amount)
                }
            }).padding([.top])
            Spacer()
        }.padding().background(Color("backgroundColor").edgesIgnoringSafeArea(.all))
    }
}
