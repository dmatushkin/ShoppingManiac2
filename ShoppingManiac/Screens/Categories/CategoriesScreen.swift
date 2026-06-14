//
//  CategoriesScreen.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 12.06.2021.
//

import SwiftUI
import FactoryKit

struct CategoriesScreen: View {
    
    @State private var model: CategoriesModel
    
    init() {
        _model = State(wrappedValue: CategoriesModel())
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(model.items) { item in
                    NavigationLink(value: item) {
                        Text(item.name)
                    }.listRowBackground(Color("backgroundColor"))
                }.onDelete(perform: {indexSet in
                    Task {
                        await model.removeStore(offsets: indexSet)
                    }
                })
            }
            .listStyle(.plain)
            .overlay {
                if model.items.isEmpty {
                    if model.searchString.isEmpty {
                        ContentUnavailableView("No categories", systemImage: "folder", description: Text("Tap Add Item to create categories."))
                    } else {
                        ContentUnavailableView.search
                    }
                }
            }
            .searchable(text: $model.searchString, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search")
            .navigationDestination(for: CategoriesItemModel.self) { item in
                EditCategoryView(model: model, item: item)
            }
            .background(Color("backgroundColor").ignoresSafeArea())
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button(action: {
                        model.showAddSheet = true
                    }) {
                        Label("Add Item", systemImage: "plus")
                    }
                    .accessibilityIdentifier("categories.addButton")
                }
            }
            .navigationTitle("Categories")
        }.onAppear(perform: {
            model.reload()
        }).sheet(isPresented: $model.showAddSheet, onDismiss: nil, content: {
            EditCategoryView(model: model, item: nil)
        })
    }
}

#if DEBUG
#Preview {
    let _ = Container.shared.dao.register(factory: { DAOStub() })
    CategoriesScreen()
}
#endif
