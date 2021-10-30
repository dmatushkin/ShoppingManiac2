//
//  AddShoppingListView.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 10.10.2021.
//

import SwiftUI
import DependencyInjection

struct AddShoppingListView: View {
    
    @State private var listName: String = ""
    let model: ShoppingModel
    
    init(model: ShoppingModel) {
        self.model = model
    }
    
    var body: some View {
        VStack {
            TextField("Shopping list name", text: $listName).textFieldStyle(.roundedBorder)
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
        }.padding().background(Color("backgroundColor").edgesIgnoringSafeArea(.all))
    }
}

struct AddShoppingListView_Previews: PreviewProvider {
    static var previews: some View {
        DIProvider.shared
            .register(forType: DAOProtocol.self, dependency: DAOStub.self)
            .showView(AddShoppingListView(model: ShoppingModel()))
    }
}
