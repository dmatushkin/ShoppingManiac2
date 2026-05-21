//
//  EditGoodView.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 27.10.2021.
//

import SwiftUI
import FactoryKit

protocol EditGoodModelProtocol: AnyObject {
    func editGood(item: GoodsItemModel?, name: String, category: String) async throws
}

struct EditGoodView<Model: EditGoodModelProtocol&Sendable>: View {
    
    let model: Model
    let item: GoodsItemModel?
    @State private var name: String = ""
    @State private var category: String = ""
    @FocusState private var goodFocused: Bool
    @FocusState private var categoryFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            RoundRectTextField(title: "Good name", input: $name, focus: $goodFocused)
            RoundRectTextField(title: "Category name", input: $category, focus: $categoryFocused)
            HStack {
                LargeCancelButton(title: "Cancel", action: {
                    dismiss()
                })
                LargeAcceptButton(title: item == nil ? "Add" : "Save", action: {
                    if name.isEmpty { return }
                    Task {
                        try await model.editGood(item: item, name: name, category: category)
                        dismiss()
                    }
                })
            }.padding([.top])
            Spacer()
        }.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button {
                    goodFocused = false
                    categoryFocused = false
                } label: {
                    Label("Dismiss keyboard", systemImage: "keyboard.chevron.compact.down")
                        .labelStyle(.iconOnly)
                }
            }
        }.padding()
            .background(Color("backgroundColor").ignoresSafeArea())
            .onAppear(perform: {
                name = item?.name ?? ""
                category = item?.category ?? ""
            }).navigationTitle("Edit good")
    }
}

#Preview {
    let _ = Container.shared.dao.register(factory: { DAOStub() })
    EditGoodView(model: GoodsModel(), item: GoodsItemModel(id: UUID().uuidString, name: "good name", category: "good category"))
}
