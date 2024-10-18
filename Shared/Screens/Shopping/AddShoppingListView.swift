//
//  AddShoppingListView.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 10.10.2021.
//

import SwiftUI
import Factory

protocol AddShoppingListModelProtocol: ObservableObject {
    func addItem(name: String) async throws
    func cancelAddingItem() async throws
}

struct AddShoppingListView<Model: AddShoppingListModelProtocol&Sendable>: View {
    
    @State private var listName: String = ""
    @FocusState private var editFocused: Bool
    let model: Model
    
    init(model: Model) {
        self.model = model
    }
    
    var body: some View {
        NavigationView {
            VStack {
                RoundRectTextField(title: "Shopping list name", input: $listName, focus: $editFocused)
                HStack {
                    LargeCancelButton(title: "Cancel", action: {
                        Task {
                            try await model.cancelAddingItem()
                        }
                    })
                    LargeAcceptButton(title: "Create", action: {
                        Task {
                            try await model.addItem(name: listName)
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
            }.navigationBarHidden(true)
                .padding()
                .background(Color("backgroundColor").edgesIgnoringSafeArea(.all))
        }        
    }
}

struct AddShoppingListView_Previews: PreviewProvider {
    static var previews: some View {
        Container.shared.dao.register(factory: { DAOStub() })
        return AddShoppingListView(model: ShoppingModel())
    }
}
