//
//  ShoppingListItemView.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 27.10.2021.
//

import SwiftUI
import DependencyInjection
import CoreData

struct ShoppingListItemView: View {
    
    private let item: ShoppingListItemModel
    @ObservedObject private var model: ShoppingListViewModel
    
    init(item: ShoppingListItemModel, model: ShoppingListViewModel) {
        self.item = item
        self.model = model
    }
    
    var body: some View {
        HStack {
            Image(systemName: item.isPurchased ? "checkmark.square" : "square").padding([.top, .bottom], 8)
            Text(item.title).padding([.top, .bottom], 8)
            Spacer()
            Text(item.amount)
        }.contentShape(Rectangle())
            .listRowBackground(Color("backgroundColor"))
            .onTapGesture {
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
}

struct ShoppingListItemView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DIProvider.shared
                .register(forType: DAOProtocol.self, dependency: DAOStub.self)
                .showView(ShoppingListItemView(item: ShoppingListItemModel(id: NSManagedObjectID(),
                                                                           uniqueId: "3452345",
                                                                           title: "Test title",
                                                                           store: "Test store",
                                                                           category: "Test category",
                                                                           categoryStoreOrder: 0,
                                                                           isPurchased: false,
                                                                           amount: "15",
                                                                           isWeight: false,
                                                                           price: "25",
                                                                           isImportant: false,
                                                                           rating: 5,
                                                                           recordId: nil), model: ShoppingListViewModel()).previewLayout(.fixed(width: 375, height: 50)))
            DIProvider.shared
                .register(forType: DAOProtocol.self, dependency: DAOStub.self)
                .showView(ShoppingListItemView(item: ShoppingListItemModel(id: NSManagedObjectID(),
                                                                           uniqueId: "1211234",
                                                                           title: "Test title",
                                                                           store: "Test store",
                                                                           category: "Test category",
                                                                           categoryStoreOrder: 0,
                                                                           isPurchased: true,
                                                                           amount: "15",
                                                                           isWeight: false,
                                                                           price: "25",
                                                                           isImportant: false,
                                                                           rating: 5,
                                                                           recordId: nil), model: ShoppingListViewModel()).previewLayout(.fixed(width: 375, height: 50)))
        }
    }
}
