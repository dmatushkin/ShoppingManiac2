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
    @StateObject private var dataModel = EditShoppingListItemViewModel()
    @FocusState private var itemNameFocused: Bool
    @FocusState private var storeNameFocused: Bool
    @FocusState private var amountFocused: Bool
    @FocusState private var priceFocused: Bool
    private let geometryStorage = GeometryStorage(coordinateSpace: "zstackCoordinateSpace")
    let model: ShoppingListViewModel
    let item: ShoppingListItemModel?
    
    init(model: ShoppingListViewModel, item: ShoppingListItemModel?) {
        self.model = model
        self.item = item
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .topLeading) {
                VStack {
                    TextField("Item name", text: $dataModel.itemName)
                        .focused($itemNameFocused)
                        .textFieldStyle(.roundedBorder)
                        .geometryAware(viewName: "goods", geometryStorage: geometryStorage)
                    TextField("Store name", text: $dataModel.storeName)
                        .focused($storeNameFocused)
                        .textFieldStyle(.roundedBorder)
                        .geometryAware(viewName: "store", geometryStorage: geometryStorage)
                    HStack {
                        TextField("Amount", text: $dataModel.amount)
                            .focused($amountFocused)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                        Picker("", selection: $dataModel.amountType) {
                            Text("Quantity").tag(0)
                            Text("Weight").tag(1)
                        }.pickerStyle(MenuPickerStyle())
                    }
                    HStack {
                        TextField("Price", text: $dataModel.price)
                            .focused($priceFocused)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                        RatingView(rating: $dataModel.rating)
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
                                    try await model.editShoppingListItem(item: item,
                                                                         name: dataModel.itemName,
                                                                         amount: dataModel.amount,
                                                                         store: dataModel.storeName,
                                                                         isWeight: dataModel.amountType == 1,
                                                                         price: dataModel.price,
                                                                         isImportant: dataModel.isImportant,
                                                                         rating: dataModel.rating)
                                } else {
                                    try await model.addShoppingListItem(name: dataModel.itemName,
                                                                        amount: dataModel.amount,
                                                                        store: dataModel.storeName,
                                                                        isWeight: dataModel.amountType == 1,
                                                                        price: dataModel.price,
                                                                        isImportant: dataModel.isImportant,
                                                                        rating: dataModel.rating)
                                }
                                
                            }
                        })
                    }.padding([.top])
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
