//
//  StoresScreen.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 12.06.2021.
//

import SwiftUI
import FactoryKit

struct StoresScreen: View {
    
    @State private var model: StoresModel
    
    init() {
        _model = State(wrappedValue: StoresModel())
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
                        ContentUnavailableView("No stores", systemImage: "storefront", description: Text("Tap Add Item to create stores."))
                    } else {
                        ContentUnavailableView.search
                    }
                }
            }
            .searchable(text: $model.searchString, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search")
            .navigationDestination(for: StoresItemModel.self) { item in
                EditStoreView(model: model, item: item)
            }
            .background(Color("backgroundColor").ignoresSafeArea())
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button(action: {
                        model.showAddSheet = true
                    }) {
                        Label("Add Item", systemImage: "plus")
                    }
                    .accessibilityIdentifier("stores.addButton")
                }
            }
            .navigationTitle("Stores")
        }.onAppear(perform: {
            model.reload()
        }).sheet(isPresented: $model.showAddSheet, onDismiss: nil, content: {
            EditStoreView(model: model, item: nil)
        })
    }
}

#if DEBUG
#Preview {
    let _ = Container.shared.dao.register(factory: { DAOStub() })
    StoresScreen()
}
#endif
