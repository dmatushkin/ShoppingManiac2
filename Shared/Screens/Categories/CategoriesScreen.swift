//
//  CategoriesScreen.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 12.06.2021.
//

import SwiftUI
import DependencyInjection

struct CategoriesScreen: View {
    
    @StateObject private var model = CategoriesModel()
    @FocusState private var editFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack {
                RoundRectTextField(title: "Search", input: $model.searchString, focus: $editFocused).padding()
                List {
                    ForEach(model.items) { item in
                        NavigationLink(destination: {
                            NavigationLazyView(EditCategoryView(model: model, item: item))
                        }, label: {
                            Text(item.name)
                        }).listRowBackground(Color("backgroundColor"))
                    }.onDelete(perform: {indexSet in
                        Task {
                            try await model.removeStore(offsets: indexSet)
                        }
                    })
                }.listStyle(.plain)
            }.background(Color("backgroundColor").edgesIgnoringSafeArea(.all))
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button(action: {
                            model.showAddSheet = true
                        }) {
                            Label("Add Item", systemImage: "plus")
                        }
                    }
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Image(systemName: "keyboard.chevron.compact.down").onTapGesture {
                            editFocused = false
                        }
                    }
                }.navigationTitle("Categories")
        }.sheet(isPresented: $model.showAddSheet, onDismiss: nil, content: {
            EditCategoryView(model: model, item: nil)
        })
    }
}

struct CategoriesScreen_Previews: PreviewProvider {
    static var previews: some View {
        DIProvider.shared
            .register(forType: DAOProtocol.self, dependency: DAOStub.self)
            .showView(CategoriesScreen())
    }
}
