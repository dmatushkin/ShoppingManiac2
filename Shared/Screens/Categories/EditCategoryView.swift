//
//  EditCategoryView.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 27.10.2021.
//

import SwiftUI
import Factory
import CoreData

protocol EditCategoryModelProtocol: ObservableObject {
    func editCategory(item: CategoriesItemModel?, name: String, goods: [String]) async throws
    func getCategoryGoods(category: CategoriesItemModel) async throws -> [GoodsItemModel]
}

struct EditCategoryView<Model: EditCategoryModelProtocol&Sendable>: View {
    
    let model: Model
    let item: CategoriesItemModel?
    @State private var name: String = ""
    @State private var goods: [String] = []
    @State private var showingPopover = false
    @FocusState private var editFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
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
                    dismiss()
                })
                LargeAcceptButton(title: item == nil ? "Add" : "Save", action: {
                    if name.isEmpty { return }
                    Task {
                        try await model.editCategory(item: item, name: name, goods: goods)
                        dismiss()
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
        Container.shared.dao.register(factory: { DAOStub() })
        return EditCategoryView(model: CategoriesModel(), item: CategoriesItemModel(id: NSManagedObjectID(), name: "Test category"))
    }
}
