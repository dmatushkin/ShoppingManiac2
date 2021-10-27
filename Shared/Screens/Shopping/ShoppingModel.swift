//
//  ShoppingModel.swift
//  ShoppingModel
//
//  Created by Dmitry Matyushkin on 10.08.2021.
//

import SwiftUI
import Combine
import DependencyInjection

@MainActor
final class ShoppingModel: ObservableObject {
    
    @Autowired(cacheType: .share) private var dao: DAOProtocol
    
    @Published var items: [ShoppingListModel] = []
    @Published var showAddSheet: Bool = false
    @Published var itemToOpen: ShoppingListModel?
    
    init() {
        Task {
            items = try await dao.getShoppingLists()
        }
    }
            
    func addItem(name: String) async throws {
        showAddSheet = false
        let item = try await dao.addShoppingList(name: name)
        items = try await dao.getShoppingLists()
        itemToOpen = item
    }

    func deleteItems(offsets: IndexSet) async throws {
        let itemsToDelete = items.enumerated().filter({ offsets.contains($0.offset) }).map({ $0.element })
        for item in itemsToDelete {
            try await dao.deleteShoppingList(item)
        }
        items = try await dao.getShoppingLists()
    }
}
