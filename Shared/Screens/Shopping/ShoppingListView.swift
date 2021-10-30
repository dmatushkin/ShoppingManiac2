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
                    }
                }.onDelete(perform: {indexSet in
                    Task {
                        try await model.removeShoppingListItem(offsets: indexSet)
                    }
                })
            }
            HStack {
                Spacer()
                Image("add_purchase_large").onTapGesture {
                    model.showAddSheet = true
                }.padding()
            }
        }.onAppear(perform: { model.listModel = listModel })
            .toolbar {
#if os(iOS)
                EditButton()
#endif
            }
            .navigationTitle(Text(listModel.title))
            .background(Color("backgroundColor").edgesIgnoringSafeArea(.all))
            .sheet(isPresented: $model.showAddSheet, onDismiss: nil, content: {
                AddShoppingListItemView(model: model)
            })
    }
}

struct ShoppingListView_Previews: PreviewProvider {
    static var previews: some View {
        DIProvider.shared
            .register(forType: DAOProtocol.self, dependency: DAOStub.self)
            .showView(ShoppingListView(listModel: ShoppingListModel(id: NSManagedObjectID(), title: "test list")))
    }
}
