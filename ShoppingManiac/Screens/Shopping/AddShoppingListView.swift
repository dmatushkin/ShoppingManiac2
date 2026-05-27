//
//  AddShoppingListView.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 10.10.2021.
//

import SwiftUI
import FactoryKit

@MainActor
protocol AddShoppingListModelProtocol: AnyObject {
    func addItem(name: String) async
    func cancelAddingItem() async
}

struct AddShoppingListView<Model: AddShoppingListModelProtocol>: View {
    
    @State private var listName: String = ""
    @FocusState private var editFocused: Bool
    let model: Model
    
    init(model: Model) {
        self.model = model
    }
    
    var body: some View {
        VStack {
            RoundRectTextField(title: "Shopping list name", input: $listName, focus: $editFocused)
            HStack {
                LargeCancelButton(title: "Cancel", action: {
                    editFocused = false
                    Task {
                        await model.cancelAddingItem()
                    }
                })
                LargeAcceptButton(title: "Create", action: {
                    editFocused = false
                    Task {
                        await model.addItem(name: listName)
                    }
                })
            }.padding([.top])
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                Button {
                    editFocused = false
                } label: {
                    Label("Dismiss keyboard", systemImage: "keyboard.chevron.compact.down")
                        .labelStyle(.iconOnly)
                }
            }
        }
        .padding()
        .background(Color("backgroundColor").ignoresSafeArea())
    }
}

#Preview {
    let _ = Container.shared.dao.register(factory: { DAOStub() })
    AddShoppingListView(model: ShoppingModel())
}
