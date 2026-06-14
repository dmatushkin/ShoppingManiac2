//
//  GoodsScreen.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 12.06.2021.
//

import SwiftUI
import FactoryKit

struct GoodsScreen: View {
    
    @State private var model: GoodsModel
    
    init() {
        _model = State(wrappedValue: GoodsModel())
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
                        await model.removeGood(offsets: indexSet)
                    }
                })
            }
            .listStyle(.plain)
            .overlay {
                if model.items.isEmpty {
                    if model.searchString.isEmpty {
                        ContentUnavailableView("No goods", systemImage: "bag", description: Text("Tap Add Item to create reusable goods."))
                    } else {
                        ContentUnavailableView.search
                    }
                }
            }
            .searchable(text: $model.searchString, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search")
            .navigationDestination(for: GoodsItemModel.self) { item in
                EditGoodView(model: model, item: item)
            }
            .background(Color("backgroundColor").ignoresSafeArea())
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button(action: {
                        model.showAddSheet = true
                    }) {
                        Label("Add Item", systemImage: "plus")
                    }
                    .accessibilityIdentifier("goods.addButton")
                }
            }
            .navigationTitle("Goods")
        }.onAppear(perform: {
            model.reload()
        }).sheet(isPresented: $model.showAddSheet, onDismiss: nil, content: {
            EditGoodView(model: model, item: nil)
        })
    }
}

#if DEBUG
#Preview {
    let _ = Container.shared.dao.register(factory: { DAOStub() })
    GoodsScreen()
}
#endif
