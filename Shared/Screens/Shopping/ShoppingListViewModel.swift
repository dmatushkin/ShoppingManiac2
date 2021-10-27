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
    var listModel: ShoppingListModel? {
        didSet {
            Task {
                try await reloadList()
            }
        }
    }
    
    func addShoppingListItem(name: String, amount: String) async throws {
        showAddSheet = false
        guard let listModel = listModel else { return }
        try await dao.addShoppingListItem(list: listModel, name: name, amount: amount)
        listItems = try await dao.getShoppingListItems(list: listModel)
    }
    
    func removeShoppingListItem(offsets: IndexSet) async throws {
        guard let listModel = listModel else { return }
        let itemsToDelete = listItems.enumerated().filter({ offsets.contains($0.offset) }).map({ $0.element })
        for item in itemsToDelete {
            try await dao.removeShoppingListItem(item: item)
        }
        listItems = try await dao.getShoppingListItems(list: listModel)
    }
    
    func togglePurchased(item: ShoppingListItemModel) async throws {
        guard let listModel = listModel else { return }
        try await dao.togglePurchasedShoppingListItem(item: item)
        listItems = try await dao.getShoppingListItems(list: listModel)
    }
    
    @Published var listItems: [ShoppingListItemModel] = []
    
    private func reloadList() async throws {
        guard let listModel = listModel else { return }
        listItems = try await dao.getShoppingListItems(list: listModel)
    }
}
