//
//  AddGoodToCategoryView.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 21.01.2022.
//

import SwiftUI

struct AddGoodToCategoryView: View {
    
    @State private var dataModel: AddGoodToCategoryModel
    @Binding var goods: [String]
    @Binding var showingPopover: Bool
    @FocusState private var goodFocused: Bool
    private let geometryStorage = GeometryStorage(coordinateSpace: "zstackCoordinateSpace")
    
    init(goods: Binding<[String]>, showingPopover: Binding<Bool>) {
        _dataModel = State(wrappedValue: AddGoodToCategoryModel())
        _goods = goods
        _showingPopover = showingPopover
    }
    
    var body: some View {
        ZStack {
            VStack {
                RoundRectTextField(title: "Good name", input: $dataModel.itemName, focus: $goodFocused)
                    .geometryAware(viewName: "goods", geometryStorage: geometryStorage)
                HStack {
                    LargeCancelButton(title: "Cancel", action: {
                        showingPopover = false
                    })
                    LargeAcceptButton(title: "Add", action: {
                        let itemName = dataModel.itemName.shoppingNormalizedName
                        if itemName.isEmpty { return }
                        if !goods.contains(where: { $0.shoppingCanonicalName == itemName.shoppingCanonicalName }) {
                            goods = (goods + [itemName]).sorted()
                        }
                        dataModel.itemName = ""
                        showingPopover = false
                    })
                }.padding([.top])
                Spacer()
            }.toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button {
                        goodFocused = false
                    } label: {
                        Label("Dismiss keyboard", systemImage: "keyboard.chevron.compact.down")
                            .labelStyle(.iconOnly)
                    }
                }
            }
            AutocompletionList(items: $dataModel.goodsNames,
                               search: $dataModel.itemName,
                               focus: $goodFocused,
                               offset: geometryStorage.getFrame(viewName: "goods").offset)
        }.padding()
            .background(Color("backgroundColor").ignoresSafeArea())
    }
}
