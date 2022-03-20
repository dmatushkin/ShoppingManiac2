//
//  AddCategoryToStoreView.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 21.01.2022.
//

import SwiftUI

struct AddCategoryToStoreView: View {
    @StateObject private var dataModel: AddCategoryToStoreModel
    @Binding var categories: [String]
    @Binding var showingPopover: Bool
    @FocusState private var categoryFocused: Bool
    private let geometryStorage = GeometryStorage(coordinateSpace: "zstackCoordinateSpace")
    
    init(categories: Binding<[String]>, showingPopover: Binding<Bool>) {
        _dataModel = StateObject(wrappedValue: AddCategoryToStoreModel())
        _categories = categories
        _showingPopover = showingPopover
    }
    
    var body: some View {
        ZStack {
            VStack {
                RoundRectTextField(title: "Category name", input: $dataModel.itemName, focus: $categoryFocused)
                    .geometryAware(viewName: "categories", geometryStorage: geometryStorage)
                HStack {
                    LargeCancelButton(title: "Cancel", action: {
                        showingPopover = false
                    })
                    LargeAcceptButton(title: "Add", action: {
                        if dataModel.itemName.isEmpty { return }
                        if !categories.contains(dataModel.itemName) {
                            categories.append(dataModel.itemName)
                        }                        
                        dataModel.itemName = ""
                        showingPopover = false
                    })
                }.padding([.top])
                Spacer()
            }.toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Image(systemName: "keyboard.chevron.compact.down").onTapGesture {
                        categoryFocused = false
                    }
                }
            }
            AutocompletionList(items: $dataModel.categoryNames,
                               search: $dataModel.itemName,
                               focus: $categoryFocused,
                               offset: geometryStorage.getFrame(viewName: "categories").offset)
        }.padding()
            .background(Color("backgroundColor").edgesIgnoringSafeArea(.all))
    }
}
