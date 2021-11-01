//
//  ShoppingListViewModel.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 26.10.2021.
//

import SwiftUI
import Combine
import DependencyInjection

@MainActor
final class ShoppingListViewModel: ObservableObject {
    
    @Autowired(cacheType: .share) private var dao: DAOProtocol
    
    @Published var showAddSheet: Bool = false
    @Published var itemToShow: ShoppingListItemModel?
    @Published var output: ShoppingListOutput = ShoppingListOutput(sections: [], items: [])
    
    private let sorter = ShoppingListSorter()
    
    var listModel: ShoppingListModel? {
        didSet {
            Task {
                try await reloadList()
            }
        }
    }
    
    func addShoppingListItem(name: String,
                             amount: String,
                             store: String,
                             isWeight: Bool,
                             price: String,
                             isImportant: Bool,
                             rating: Int) async throws {
        showAddSheet = false
        guard let listModel = listModel else { return }
        try await dao.addShoppingListItem(list: listModel,
                                          name: name,
                                          amount: amount,
                                          store: store,
                                          isWeight: isWeight,
                                          price: price,
                                          isImportant: isImportant,
                                          rating: rating)
        output = sorter.sort(try await dao.getShoppingListItems(list: listModel))
    }
    
    func editShoppingListItem(item: ShoppingListItemModel,
                              name: String,
                              amount: String,
                              store: String,
                              isWeight: Bool,
                              price: String,
                              isImportant: Bool,
                              rating: Int) async throws {
        
        guard let listModel = listModel else { return }
        try await dao.editShoppingListItem(item: item,
                                           name: name,
                                           amount: amount,
                                           store: store,
                                           isWeight: isWeight,
                                           price: price,
                                           isImportant: isImportant,
                                           rating: rating)
        output = sorter.sort(try await dao.getShoppingListItems(list: listModel))
        itemToShow = nil
    }
        
    func cancelAddingItem() async throws {
        showAddSheet = false
        itemToShow = nil
    }
    
    func removeShoppingListItem(item: ShoppingListItemModel) async throws {
        guard let listModel = listModel else { return }
        try await dao.removeShoppingListItem(item: item)
        let items = try await dao.getShoppingListItems(list: listModel)
        withAnimation {
            output = sorter.sort(items)
        }
        
    }
    
    func togglePurchased(item: ShoppingListItemModel) async throws {
        guard let listModel = listModel else { return }
        try await dao.togglePurchasedShoppingListItem(item: item)
        output = sorter.sort(try await dao.getShoppingListItems(list: listModel))
    }
        
    private func reloadList() async throws {
        guard let listModel = listModel else { return }        
        output = sorter.sort(try await dao.getShoppingListItems(list: listModel))
    }
}
