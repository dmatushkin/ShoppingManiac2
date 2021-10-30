//
//  ShoppingListView.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 26.10.2021.
//

import SwiftUI
import DependencyInjection
import CoreData

struct ShoppingListView: View {
    
    @StateObject private var model = ShoppingListViewModel()
    private let listModel: ShoppingListModel
    
    init(listModel: ShoppingListModel) {
        self.listModel = listModel
    }
    
    var body: some View {
        VStack {
            List {
                ForEach(model.listItems) {item in
                    ShoppingListItemView(item: item).onTapGesture {
                        Task {
                            try await model.togglePurchased(item: item)
                        }
                    }.swipeActions {
                        Button("Delete") {
                            Task {
                                try await model.removeShoppingListItem(item: item)
                            }
                        }.tint(.red)
                        Button("Edit") {
                            model.itemToShow = item
                        }
                    }
                }
            }.listStyle(.grouped)
        }.onAppear(perform: { model.listModel = listModel })
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Image(systemName: "square.and.arrow.up").onTapGesture {
                    }
                    Image("add_purchase_large").onTapGesture {
                        model.showAddSheet = true
                    }
                }
            }
            .navigationTitle(Text(listModel.title))
            .background(Color("backgroundColor").edgesIgnoringSafeArea(.all))
            .sheet(isPresented: $model.showAddSheet, onDismiss: nil, content: {
                EditShoppingListItemView(model: model, item: nil)
            }).sheet(item: $model.itemToShow) { item in
                EditShoppingListItemView(model: model, item: item)
            }
    }
}

struct ShoppingListView_Previews: PreviewProvider {
    static var previews: some View {
        DIProvider.shared
            .register(forType: DAOProtocol.self, dependency: DAOStub.self)
            .showView(
                NavigationView {
                    ShoppingListView(listModel: ShoppingListModel(id: NSManagedObjectID(), title: "test list"))
                }
            )
    }
}
