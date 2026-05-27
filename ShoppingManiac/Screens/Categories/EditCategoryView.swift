//
//  EditCategoryView.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 27.10.2021.
//

import SwiftUI
import FactoryKit

@MainActor
protocol EditCategoryModelProtocol: AnyObject {
    func editCategory(item: CategoriesItemModel?, name: String, goods: [String]) async
    func getCategoryGoods(category: CategoriesItemModel) async -> [GoodsItemModel]
}

struct EditCategoryView<Model: EditCategoryModelProtocol>: View {
    
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
                ForEach(Array(goods.enumerated()), id: \.offset) { _, item in
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
                        await model.editCategory(item: item, name: name, goods: goods)
                        dismiss()
                    }
                })
            }.padding([.top])
            Spacer()
        }.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button {
                    editFocused = false
                } label: {
                    Label("Dismiss keyboard", systemImage: "keyboard.chevron.compact.down")
                        .labelStyle(.iconOnly)
                }
            }
        }.padding()
            .background(Color("backgroundColor").ignoresSafeArea())
            .task(id: item?.id) {
                name = item?.name ?? ""
                if let item = item {
                    goods = await model.getCategoryGoods(category: item).map({ $0.name })
                } else {
                    goods = []
                }
            }
            .navigationTitle("Edit category")
    }
}

#Preview {
    let _ = Container.shared.dao.register(factory: { DAOStub() })
    EditCategoryView(model: CategoriesModel(), item: CategoriesItemModel(id: UUID().uuidString, name: "Test category"))
}
