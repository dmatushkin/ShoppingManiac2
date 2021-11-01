//
//  AddShoppingListItemView.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 27.10.2021.
//

import SwiftUI
import DependencyInjection
import CoreData

struct EditShoppingListItemView: View {
    
    @State private var itemName: String = ""
    @State private var storeName: String = ""
    @State private var amount: String = ""
    @State private var amountType: Int = 0
    @State private var price: String = ""
    @State private var isImportant: Bool = false
    @State private var rating: Int = 0
    @State private var shouldShowGoodsPanel: Bool = false
    @State private var shouldShowStoresPanel: Bool = false
    let model: ShoppingListViewModel
    let item: ShoppingListItemModel?
    
    init(model: ShoppingListViewModel, item: ShoppingListItemModel?) {
        self.model = model
        self.item = item
    }
    
    var body: some View {
        VStack {
            TextField("Item name", text: $itemName).textFieldStyle(.roundedBorder).onTapGesture {
                shouldShowGoodsPanel = true
            }
            TextField("Store name", text: $storeName).textFieldStyle(.roundedBorder).onTapGesture {
                shouldShowStoresPanel = true
            }
            HStack {
                TextField("Amount", text: $amount).textFieldStyle(.roundedBorder).keyboardType(.decimalPad)
                Picker("", selection: $amountType) {
                    Text("Quantity").tag(0)
                    Text("Weight").tag(1)
                }.pickerStyle(MenuPickerStyle())
            }
            HStack {
                TextField("Price", text: $price).textFieldStyle(.roundedBorder).keyboardType(.decimalPad)
                RatingView(rating: $rating)
            }
            Toggle("Is important", isOn: $isImportant)
            HStack {
                LargeCancelButton(title: "Cancel", action: {
                    Task {
                        try await model.cancelAddingItem()
                    }
                })
                LargeAcceptButton(title: item == nil ? "Add" : "Save", action: {
                    if itemName.isEmpty { return }
                    Task {
                        if let item = item {
                            try await model.editShoppingListItem(item: item,
                                                                 name: itemName,
                                                                 amount: amount,
                                                                 store: storeName,
                                                                 isWeight: amountType == 1,
                                                                 price: price,
                                                                 isImportant: isImportant,
                                                                 rating: rating)
                        } else {
                            try await model.addShoppingListItem(name: itemName,
                                                                amount: amount,
                                                                store: storeName,
                                                                isWeight: amountType == 1,
                                                                price: price,
                                                                isImportant: isImportant,
                                                                rating: rating)
                        }
                        
                    }
                })
            }.padding([.top])
            Spacer()
        }.padding()
            .background(Color("backgroundColor").edgesIgnoringSafeArea(.all))
            .sheet(isPresented: $shouldShowGoodsPanel, onDismiss: nil) {
                AutocompletionPanel(textInput: $itemName, mode: .good)
            }
            .sheet(isPresented: $shouldShowStoresPanel, onDismiss: nil) {
                AutocompletionPanel(textInput: $storeName, mode: .store)
            }
            .onAppear(perform: {
                if let item = item {
                    itemName = item.title
                    storeName = item.store
                    amount = item.amount
                    amountType = item.isWeight ? 1 : 0
                    price = item.price
                    isImportant = item.isImportant
                    rating = item.rating
                } else {
                    itemName = ""
                    storeName = ""
                    amount = ""
                    amountType = 0
                    price = ""
                    isImportant = false
                    rating = 0
                }
            })
    }
}

struct AddShoppingListItemView_Previews: PreviewProvider {
    static var previews: some View {
        DIProvider.shared
            .register(forType: DAOProtocol.self, dependency: DAOStub.self)
            .showView(EditShoppingListItemView(model: ShoppingListViewModel(), item: ShoppingListItemModel(id: NSManagedObjectID(),
                                                                                                           title: "test 1",
                                                                                                           store: "test 2",
                                                                                                           category: "test category",
                                                                                                           categoryStoreOrder: 0,
                                                                                                           isPurchased: false,
                                                                                                           amount: "10",
                                                                                                           isWeight: false,
                                                                                                           price: "20",
                                                                                                           isImportant: false,
                                                                                                           rating: 3)))
    }
}
