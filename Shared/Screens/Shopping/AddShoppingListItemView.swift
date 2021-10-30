//
//  AddShoppingListItemView.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 27.10.2021.
//

import SwiftUI
import DependencyInjection

struct AddShoppingListItemView: View {
    
    @State private var itemName: String = ""
    @State private var storeName: String = ""
    @State private var amount: String = ""
    @State private var amountType: Int = 0
    @State private var price: String = ""
    @State private var isImportant: Bool = false
    @State private var maxButtonWidth: CGFloat = .zero
    @State private var rating: Int = 0
    let model: ShoppingListViewModel
    
    init(model: ShoppingListViewModel) {
        self.model = model
    }
    
    var body: some View {
        VStack {
            TextField("Item name", text: $itemName).textFieldStyle(.roundedBorder)
            TextField("Store name", text: $storeName).textFieldStyle(.roundedBorder)
            HStack {
                TextField("Amount", text: $amount).textFieldStyle(.roundedBorder)
                Picker("", selection: $amountType) {
                    Text("Quantity").tag(0)
                    Text("Weight").tag(1)
                }.pickerStyle(MenuPickerStyle())
            }
            HStack {
                TextField("Price", text: $price).textFieldStyle(.roundedBorder)
                RatingView(rating: $rating)
            }
            Toggle("Is important", isOn: $isImportant)
            HStack {
                LargeCancelButton(title: "Cancel", action: {
                    model.showAddSheet = false
                })
                LargeAcceptButton(title: "Add", action: {
                    if itemName.isEmpty { return }
                    Task {
                        try await model.addShoppingListItem(name: itemName,
                                                            amount: amount,
                                                            store: storeName,
                                                            isWeight: amountType == 0,
                                                            price: price,
                                                            isImportant: isImportant,
                                                            rating: rating)
                    }
                })
            }.padding([.top])            
            Spacer()
        }.padding().background(Color("backgroundColor").edgesIgnoringSafeArea(.all))
    }
}

struct AddShoppingListItemView_Previews: PreviewProvider {
    static var previews: some View {
        DIProvider.shared
            .register(forType: DAOProtocol.self, dependency: DAOStub.self)
            .showView(AddShoppingListItemView(model: ShoppingListViewModel()))
    }
}
