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
                ForEach(model.output.sections) { section in
                    Section(section.title) {
                        ForEach(section.subsections) { subsection in
                            Text(subsection.title).font(Font.caption).listRowSeparator(.hidden)
                            ForEach(subsection.items) { item in
                                ShoppingListItemView(item: item, model: model)
                            }
                        }
                        ForEach(section.items) { item in
                            ShoppingListItemView(item: item, model: model)
                        }
                    }.listRowBackground(Color("backgroundColor"))
                    ForEach(model.output.items) { item in
                        ShoppingListItemView(item: item, model: model)
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
