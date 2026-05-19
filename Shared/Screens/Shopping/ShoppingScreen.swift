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
    
    @State private var model: ShoppingModel
    @State private var path: [ShoppingListModel] = []
    
    init() {
        _model = State(wrappedValue: ShoppingModel())
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            List {
                ForEach(model.items) { item in
                    NavigationLink(value: item) {
                        Text(item.title)
                    }.listRowBackground(Color("backgroundColor"))
                }
                .onDelete(perform: {indexSet in
                    Task {
                        try await model.deleteItems(offsets: indexSet)
                    }
                })
            }.listStyle(.grouped)
                .background(Color("backgroundColor").ignoresSafeArea())
                .navigationDestination(for: ShoppingListModel.self) { item in
                    ShoppingListView(listModel: item)
                }
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
            }.background(Color("backgroundColor").ignoresSafeArea())
        }.sheet(isPresented: $model.showAddSheet, onDismiss: nil, content: {
            AddShoppingListView(model: model)
        }).onChange(of: model.itemToOpen) { _, item in
            guard let item else { return }
            path.append(item)
            model.itemToOpen = nil
        }
    }
}

struct ShoppingScreen_Previews: PreviewProvider {
    static var previews: some View {
        Container.shared.dao.register(factory: { DAOStub() })
        return ShoppingScreen()
    }
}
