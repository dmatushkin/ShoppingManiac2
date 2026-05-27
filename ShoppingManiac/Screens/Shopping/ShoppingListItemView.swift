//
//  ShoppingListItemView.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 27.10.2021.
//

import SwiftUI
import FactoryKit

@MainActor
protocol ShoppingListItemModelProtocol: AnyObject {
    func togglePurchased(item: ShoppingListItemModel) async
    func removeShoppingListItem(item: ShoppingListItemModel) async
    func editItem(item: ShoppingListItemModel) async
}

struct ShoppingListItemView<Model: ShoppingListItemModelProtocol>: View  {
    
    private let item: ShoppingListItemModel
    private let model: Model
    
    init(item: ShoppingListItemModel, model: Model) {
        self.item = item
        self.model = model
    }
    
    var body: some View {
        Button {
            Task {
                await model.togglePurchased(item: item)
            }
        } label: {
            HStack {
                Image(systemName: item.isPurchased ? "checkmark.square" : "square").padding([.top, .bottom], 8)
                Text(item.title).padding([.top, .bottom], 8)
                Spacer()
                Text(item.amount)
            }.contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(item.isImportant ? Color("importantItemColor") : Color("backgroundColor"))
        .swipeActions {
                Button("Delete") {
                    Task {
                        await model.removeShoppingListItem(item: item)
                    }
                }.tint(.red)
                Button("Edit") {
                    Task {
                        await model.editItem(item: item)
                    }
                }
        }
    }
}

#Preview {
    let _ = Container.shared.dao.register(factory: { DAOStub() })
    Group {
        ShoppingListItemView(item: ShoppingListItemModel(id: UUID().uuidString,
                                                                       title: "Test title",
                                                                       store: "Test store",
                                                                       category: "Test category",
                                                                       categoryStoreOrder: 0,
                                                                       isPurchased: false,
                                                                       amount: "15",
                                                                       isWeight: false,
                                                                       price: "25",
                                                                       isImportant: false,
                                                                       rating: 5), model: ShoppingListViewModel()).frame(width: 375, height: 50)
        ShoppingListItemView(item: ShoppingListItemModel(id: UUID().uuidString,
                                                                       title: "Test title",
                                                                       store: "Test store",
                                                                       category: "Test category",
                                                                       categoryStoreOrder: 0,
                                                                       isPurchased: true,
                                                                       amount: "15",
                                                                       isWeight: false,
                                                                       price: "25",
                                                                       isImportant: false,
                                                                       rating: 5), model: ShoppingListViewModel()).frame(width: 375, height: 50)
    }
}
