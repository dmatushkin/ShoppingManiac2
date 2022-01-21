//
//  EditCategoryView.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 27.10.2021.
//

import SwiftUI
import DependencyInjection
import CoreData

struct EditCategoryView: View {
    
    let model: CategoriesModel
    let item: CategoriesItemModel?
    @State private var name: String = ""
    @State private var goods: [String] = []
    @State private var showingPopover = false
    @FocusState private var editFocused: Bool
    @Environment(\.presentationMode) var presentation
    
    var body: some View {
        VStack {
            RoundRectTextField(title: "Category name", input: $name, focus: $editFocused)
            HStack {
                Text("Goods")
                Spacer()
                Button("Add") {
                    showingPopover = true
                }.sheet(isPresented: $showingPopover, onDismiss: nil) {
                    AddGoodToCategoryView(goods: $goods, showingPopover: $showingPopover)
                }
            }
            List {
                ForEach(goods, id: \.self) { item in
                    Text(item)
                }.onDelete(perform: { indexSet in
                    if let index = indexSet.first {
                        goods.remove(at: index)
                    }
                })
            }.listStyle(.plain)
            HStack {
                LargeCancelButton(title: "Cancel", action: {
                    presentation.wrappedValue.dismiss()
                })
                LargeAcceptButton(title: item == nil ? "Add" : "Save", action: {
                    if name.isEmpty { return }
                    Task {
                        try await model.editCategory(item: item, name: name, goods: goods)
                        presentation.wrappedValue.dismiss()
                    }
                })
            }.padding([.top])
            Spacer()
        }.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Image(systemName: "keyboard.chevron.compact.down").onTapGesture {
                    editFocused = false
                }
            }
        }.padding()
            .background(Color("backgroundColor").edgesIgnoringSafeArea(.all))
            .onAppear(perform: {
                name = item?.name ?? ""
                if let item = item {
                    Task {
                        goods = try await model.getCategoryGoods(category: item).map({ $0.name })
                    }
                }
            }).navigationTitle("Edit category")
    }
}

struct EditCategoryView_Previews: PreviewProvider {
    static var previews: some View {
        DIProvider.shared
            .register(forType: DAOProtocol.self, dependency: DAOStub.self)
            .showView(EditCategoryView(model: CategoriesModel(), item: CategoriesItemModel(id: NSManagedObjectID(), name: "Test category")))
    }
}
