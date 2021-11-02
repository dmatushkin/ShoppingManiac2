//
//  EditGoodView.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 27.10.2021.
//

import SwiftUI
import DependencyInjection
import CoreData

struct EditGoodView: View {
    
    let model: GoodsModel
    let item: GoodsItemModel?
    @State private var name: String = ""
    @State private var category: String = ""
    @FocusState private var goodFocused: Bool
    @FocusState private var categoryFocused: Bool
    @Environment(\.presentationMode) var presentation
    
    var body: some View {
        VStack {
            RoundRectTextField(title: "Good name", input: $name, focus: $goodFocused)
            RoundRectTextField(title: "Category name", input: $category, focus: $categoryFocused)
            HStack {
                LargeCancelButton(title: "Cancel", action: {
                    presentation.wrappedValue.dismiss()
                })
                LargeAcceptButton(title: item == nil ? "Add" : "Save", action: {
                    if name.isEmpty { return }
                    Task {
                        try await model.editGood(item: item, name: name, category: category)
                        presentation.wrappedValue.dismiss()
                    }
                })
            }.padding([.top])
            Spacer()
        }.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Image(systemName: "keyboard.chevron.compact.down").onTapGesture {
                    goodFocused = false
                    categoryFocused = false
                }
            }
        }.padding()
            .background(Color("backgroundColor").edgesIgnoringSafeArea(.all))
            .onAppear(perform: {
                name = item?.name ?? ""
                category = item?.category ?? ""
            }).navigationTitle("Edit good")
    }
}

struct EditGoodView_Previews: PreviewProvider {
    static var previews: some View {
        DIProvider.shared
            .register(forType: DAOProtocol.self, dependency: DAOStub.self)
            .showView(EditGoodView(model: GoodsModel(), item: GoodsItemModel(id: NSManagedObjectID(), name: "good name", category: "good category")))
    }
}
