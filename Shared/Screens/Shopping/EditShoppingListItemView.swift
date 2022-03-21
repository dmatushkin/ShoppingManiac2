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
    @StateObject private var dataModel: EditShoppingListItemViewModel
    @FocusState private var itemNameFocused: Bool
    @FocusState private var storeNameFocused: Bool
    @FocusState private var amountFocused: Bool
    @FocusState private var priceFocused: Bool
    private let geometryStorage = GeometryStorage(coordinateSpace: "zstackCoordinateSpace")
    let model: ShoppingListViewModel
    let item: ShoppingListItemModel?
    
    init(model: ShoppingListViewModel, item: ShoppingListItemModel?) {
        _dataModel = StateObject(wrappedValue: EditShoppingListItemViewModel())
        self.model = model
        self.item = item
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .topLeading) {
                VStack {
                    RoundRectTextField(title: "Item name", input: $dataModel.itemName, focus: $itemNameFocused)
                        .geometryAware(viewName: "goods", geometryStorage: geometryStorage)
                    RoundRectTextField(title: "Store name", input: $dataModel.storeName, focus: $storeNameFocused)
                        .geometryAware(viewName: "store", geometryStorage: geometryStorage)
                    HStack(alignment: .bottom) {
                        RoundRectTextField(title: "Amount", input: $dataModel.amount, focus: $amountFocused)
                            .keyboardType(.decimalPad)
                        Picker("", selection: $dataModel.amountType) {
                            Text("Quantity").tag(0)
                            Text("Weight").tag(1)
                        }.pickerStyle(MenuPickerStyle()).padding([.bottom], 2)
                    }
                    HStack(alignment: .bottom) {
                        RoundRectTextField(title: "Price", input: $dataModel.price, focus: $priceFocused)
                            .keyboardType(.decimalPad)
                        RatingView(rating: $dataModel.rating).padding([.bottom], 1)
                    }
                    Toggle("Is important", isOn: $dataModel.isImportant)
                    HStack {
                        LargeCancelButton(title: "Cancel", action: {
                            Task {
                                try await model.cancelAddingItem()
                            }
                        })
                        LargeAcceptButton(title: item == nil ? "Add" : "Save", action: {
                            if dataModel.itemName.isEmpty { return }
                            Task {
                                if let item = item {
                                    try await model.editShoppingListItem(item: item, model: dataModel)
                                } else {
                                    try await model.addShoppingListItem(model: dataModel)
                                }
                                
                            }
                        })
                    }
                    Spacer()
                }
                AutocompletionList(items: $dataModel.goodsNames,
                                   search: $dataModel.itemName,
                                   focus: $itemNameFocused,
                                   offset: geometryStorage.getFrame(viewName: "goods").offset)
                AutocompletionList(items: $dataModel.storesNames,
                                   search: $dataModel.storeName,
                                   focus: $storeNameFocused,
                                   offset: geometryStorage.getFrame(viewName: "store").offset)
            }.navigationBarHidden(true)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Image(systemName: "keyboard.chevron.compact.down").onTapGesture {
                            itemNameFocused = false
                            storeNameFocused = false
                            amountFocused = false
                            priceFocused = false
                        }
                    }
                }.coordinateSpace(name: geometryStorage.coordinateSpace)
                .padding()
                .background(Color("backgroundColor").edgesIgnoringSafeArea(.all))
                .onAppear(perform: {
                    dataModel.setItem(item)
                })
        }
    }
}

struct AddShoppingListItemView_Previews: PreviewProvider {
    static var previews: some View {
        DIProvider.shared
            .register(forType: DAOProtocol.self, dependency: DAOStub.self)
            .showView(EditShoppingListItemView(model: ShoppingListViewModel(),
                                               item: ShoppingListItemModel(id: NSManagedObjectID(),
                                                                           uniqueId: "112341234",
                                                                           title: "test 1",
                                                                           store: "test 2",
                                                                           category: "test category",
                                                                           categoryStoreOrder: 0,
                                                                           isPurchased: false,
                                                                           amount: "10",
                                                                           isWeight: false,
                                                                           price: "20",
                                                                           isImportant: false,
                                                                           rating: 3,
                                                                           recordId: nil)))
    }
}
