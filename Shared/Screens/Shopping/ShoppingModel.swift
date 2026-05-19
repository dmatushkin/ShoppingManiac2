//
//  ShoppingModel.swift
//  ShoppingModel
//
//  Created by Dmitry Matyushkin on 10.08.2021.
//

import SwiftUI
import Combine
import Factory
import Observation

@MainActor
@Observable
final class ShoppingModel: AddShoppingListModelProtocol {
    
    @ObservationIgnored
    @Injected(\.dao) private var dao: DAOProtocol
    
    var items: [ShoppingListModel] = []
    var showAddSheet: Bool = false
    var itemToOpen: ShoppingListModel?
    @ObservationIgnored
    private var cancellable = Set<AnyCancellable>()
    @ObservationIgnored
    private var reloadTask: Task<Void, Never>?
    
    init() {
        reloadItems()
        GlobalCommands.reloadTopList.sink(receiveValue: {[weak self] in
            self?.reloadItems()
        }).store(in: &cancellable)
    }
    
    deinit {
        reloadTask?.cancel()
    }
    
    private func reloadItems() {
        reloadTask?.cancel()
        reloadTask = Task {
            do {
                let lists = try await dao.getShoppingLists()
                try Task.checkCancellation()
                items = lists
            } catch is CancellationError {
            } catch {
            }
        }
    }
            
    func addItem(name: String) async throws {
        showAddSheet = false
        let item = try await dao.addShoppingList(name: name, date: Date(), uniqueId: nil)
        items = try await dao.getShoppingLists()
        itemToOpen = item
    }
    
    func cancelAddingItem() async throws {
        showAddSheet = false
    }

    func deleteItems(offsets: IndexSet) async throws {
        let itemsToDelete = items.enumerated().filter({ offsets.contains($0.offset) }).map({ $0.element })
        for item in itemsToDelete {
            try await dao.removeShoppingList(item)
        }
        items = try await dao.getShoppingLists()
    }
}
