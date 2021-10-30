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
    
    init(item: ShoppingListItemModel) {
        self.item = item
    }
    
    var body: some View {
        HStack {
            Image(systemName: item.isPurchased ? "checkmark.square" : "square").padding([.top, .bottom], 8)
            Text(item.title).padding([.top, .bottom], 8)
            Spacer()
            Text(item.amount)
        }.contentShape(Rectangle())
    }
}

struct ShoppingListItemView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DIProvider.shared
                .register(forType: DAOProtocol.self, dependency: DAOStub.self)
                .showView(ShoppingListItemView(item: ShoppingListItemModel(id: NSManagedObjectID(),
                                                                           title: "Test title",
                                                                           store: "Test store",
                                                                           category: "Test category",
                                                                           isPurchased: false,
                                                                           amount: "15",
                                                                           isWeight: false,
                                                                           price: "25",
                                                                           isImportant: false,
                                                                       rating: 5)).previewLayout(.fixed(width: 375, height: 50)))
            DIProvider.shared
                .register(forType: DAOProtocol.self, dependency: DAOStub.self)
                .showView(ShoppingListItemView(item: ShoppingListItemModel(id: NSManagedObjectID(),
                                                                           title: "Test title",
                                                                           store: "Test store",
                                                                           category: "Test category",
                                                                           isPurchased: true,
                                                                           amount: "15",
                                                                           isWeight: false,
                                                                           price: "25",
                                                                           isImportant: false,
                                                                           rating: 5)).previewLayout(.fixed(width: 375, height: 50)))
        }
    }
}
