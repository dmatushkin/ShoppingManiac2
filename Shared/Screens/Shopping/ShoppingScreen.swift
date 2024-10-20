//
//  ShoppingScreen.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 12.06.2021.
//

import SwiftUI
import CoreData
import Factory

struct ShoppingScreen: View {
    
    @StateObject private var model: ShoppingModel
    
    init() {
        _model = StateObject(wrappedValue: ShoppingModel())
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(model.items) { item in
                    NavigationLink(tag: item, selection: $model.itemToOpen, destination: {
                        NavigationLazyView(ShoppingListView(listModel: item))
                    }, label: {
                        Text(item.title)
                    }).listRowBackground(Color("backgroundColor"))
                }
                .onDelete(perform: {indexSet in
                    Task {
                        try await model.deleteItems(offsets: indexSet)
                    }
                })
            }.listStyle(.grouped)
                .background(Color("backgroundColor").edgesIgnoringSafeArea(.all))
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button(action: {
                            model.showAddSheet = true
                        }) {
                            Label("Add Item", systemImage: "plus")
                        }
                    }
                }.navigationTitle("Shopping lists")
            VStack {
                Spacer()
                HStack {
                    Spacer()
                }
                Spacer()
            }.background(Color("backgroundColor").edgesIgnoringSafeArea(.all))
        }.sheet(isPresented: $model.showAddSheet, onDismiss: nil, content: {
            AddShoppingListView(model: model)
        })
    }
}

struct ShoppingScreen_Previews: PreviewProvider {
    static var previews: some View {
        Container.shared.dao.register(factory: { DAOStub() })
        return ShoppingScreen()
    }
}
