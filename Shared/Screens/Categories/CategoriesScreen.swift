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
                            await model.removeStore(offsets: indexSet)
                        }
                    })
                }.listStyle(.plain)
                    .navigationDestination(for: CategoriesItemModel.self) { item in
                        EditCategoryView(model: model, item: item)
                    }
            }.background(Color("backgroundColor").ignoresSafeArea())
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        Button(action: {
                            model.showAddSheet = true
                        }) {
                            Label("Add Item", systemImage: "plus")
                        }
                    }
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button {
                            editFocused = false
                        } label: {
                            Label("Dismiss keyboard", systemImage: "keyboard.chevron.compact.down")
                                .labelStyle(.iconOnly)
                        }
                    }
                }.navigationTitle("Categories")
        }.onAppear(perform: {
            model.reload()
        }).sheet(isPresented: $model.showAddSheet, onDismiss: nil, content: {
            EditCategoryView(model: model, item: nil)
        })
    }
}

#Preview {
    let _ = Container.shared.dao.register(factory: { DAOStub() })
    CategoriesScreen()
}
