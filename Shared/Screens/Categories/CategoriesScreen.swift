//
//  CategoriesScreen.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 12.06.2021.
//

import SwiftUI
import Factory

struct CategoriesScreen: View {
    
    @State private var model: CategoriesModel
    @FocusState private var editFocused: Bool
    
    init() {
        _model = State(wrappedValue: CategoriesModel())
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                RoundRectTextField(title: "Search", input: $model.searchString, focus: $editFocused).padding()
                List {
                    ForEach(model.items) { item in
                        NavigationLink(value: item) {
                            Text(item.name)
                        }.listRowBackground(Color("backgroundColor"))
                    }.onDelete(perform: {indexSet in
                        Task {
                            try await model.removeStore(offsets: indexSet)
                        }
                    })
                }.listStyle(.plain)
                    .navigationDestination(for: CategoriesItemModel.self) { item in
                        EditCategoryView(model: model, item: item)
                    }
            }.background(Color("backgroundColor").ignoresSafeArea())
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
            VStack {
                Spacer()
                HStack {
                    Spacer()
                }
                Spacer()
            }.background(Color("backgroundColor").ignoresSafeArea())
        }.onAppear(perform: {
            model.reload()
        }).sheet(isPresented: $model.showAddSheet, onDismiss: nil, content: {
            EditCategoryView(model: model, item: nil)
        })
    }
}

struct CategoriesScreen_Previews: PreviewProvider {
    static var previews: some View {
        Container.shared.dao.register(factory: { DAOStub() })
        return CategoriesScreen()
    }
}
