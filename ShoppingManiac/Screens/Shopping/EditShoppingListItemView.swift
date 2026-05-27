//
//  AddShoppingListItemView.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 27.10.2021.
//

import SwiftUI
import FactoryKit

protocol EditShoppingListItemModelProtocol: AnyObject {
    func editShoppingListItem(item: ShoppingListItemModel, model: EditShoppingListItemViewModel) async
    func addShoppingListItem(model: EditShoppingListItemViewModel) async
    func cancelAddingItem() async
}

struct EditShoppingListItemView<Model: EditShoppingListItemModelProtocol&Sendable>: View {
    @State private var dataModel: EditShoppingListItemViewModel
    @FocusState private var itemNameFocused: Bool
    @FocusState private var storeNameFocused: Bool
    @FocusState private var amountFocused: Bool
    @FocusState private var priceFocused: Bool
    private let geometryStorage = GeometryStorage(coordinateSpace: "zstackCoordinateSpace")
    let model: Model
    let item: ShoppingListItemModel?
    
    init(model: Model, item: ShoppingListItemModel?) {
        _dataModel = State(wrappedValue: EditShoppingListItemViewModel())
        self.model = model
        self.item = item
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack {
                RoundRectTextField(title: "Item name", input: $dataModel.itemName, focus: $itemNameFocused)
                    .geometryAware(viewName: "goods", geometryStorage: geometryStorage)
                RoundRectTextField(title: "Store name", input: $dataModel.storeName, focus: $storeNameFocused)
                    .geometryAware(viewName: "store", geometryStorage: geometryStorage)
                HStack(alignment: .bottom) {
                    RoundRectTextField(title: "Amount", input: $dataModel.amount, focus: $amountFocused)
                        .decimalKeyboard()
                    Picker("", selection: $dataModel.amountType) {
                        Text("Quantity").tag(0)
                        Text("Weight").tag(1)
                    }.pickerStyle(.menu).padding([.bottom], 2)
                }
                HStack(alignment: .bottom) {
                    RoundRectTextField(title: "Price", input: $dataModel.price, focus: $priceFocused)
                        .decimalKeyboard()
                    RatingView(rating: $dataModel.rating).padding([.bottom], 1)
                }
                Toggle("Is important", isOn: $dataModel.isImportant)
                HStack {
                    LargeCancelButton(title: "Cancel", action: {
                        dismissKeyboard()
                        Task {
                            await model.cancelAddingItem()
                        }
                    })
                    LargeAcceptButton(title: item == nil ? "Add" : "Save", action: {
                        if dataModel.itemName.isEmpty { return }
                        dismissKeyboard()
                        Task {
                            if let item = item {
                                await model.editShoppingListItem(item: item, model: dataModel)
                            } else {
                                await model.addShoppingListItem(model: dataModel)
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
        }
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                Button {
                    dismissKeyboard()
                } label: {
                    Label("Dismiss keyboard", systemImage: "keyboard.chevron.compact.down")
                        .labelStyle(.iconOnly)
                }
            }
        }
        .coordinateSpace(name: geometryStorage.coordinateSpace)
        .padding()
        .background(Color("backgroundColor").ignoresSafeArea())
        .task(id: item?.id) {
            dataModel.setItem(item)
        }
    }
}

private extension View {
    @ViewBuilder
    func decimalKeyboard() -> some View {
        #if os(iOS)
        keyboardType(.decimalPad)
        #else
        self
        #endif
    }
}

#Preview {
    let _ = Container.shared.dao.register(factory: { DAOStub() })
    EditShoppingListItemView(model: ShoppingListViewModel(),
                             item: ShoppingListItemModel(id: UUID().uuidString,
                                                         title: "test 1",
                                                         store: "test 2",
                                                         category: "test category",
                                                         categoryStoreOrder: 0,
                                                         isPurchased: false,
                                                         amount: "10",
                                                         isWeight: false,
                                                         price: "20",
                                                         isImportant: false,
                                                         rating: 3))
}

private extension EditShoppingListItemView {
    func dismissKeyboard() {
        itemNameFocused = false
        storeNameFocused = false
        amountFocused = false
        priceFocused = false
    }
}
