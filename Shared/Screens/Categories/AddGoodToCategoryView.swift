//
//  AddGoodToCategoryView.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 21.01.2022.
//

import SwiftUI

struct AddGoodToCategoryView: View {
    
    @StateObject private var dataModel = AddGoodToCategoryModel()
    @Binding var goods: [String]
    @Binding var showingPopover: Bool
    @FocusState private var goodFocused: Bool
    private let geometryStorage = GeometryStorage(coordinateSpace: "zstackCoordinateSpace")
    
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
                        if dataModel.itemName.isEmpty { return }
                        goods = (goods + [dataModel.itemName]).sorted()
                        dataModel.itemName = ""
                        showingPopover = false
                    })
                }.padding([.top])
                Spacer()
            }.toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Image(systemName: "keyboard.chevron.compact.down").onTapGesture {
                        goodFocused = false
                    }
                }
            }
            AutocompletionList(items: $dataModel.goodsNames,
                               search: $dataModel.itemName,
                               focus: $goodFocused,
                               offset: geometryStorage.getFrame(viewName: "goods").offset)
        }.padding()
            .background(Color("backgroundColor").edgesIgnoringSafeArea(.all))
    }
}
