//
//  ShoppingModel.swift
//  ShoppingModel
//
//  Created by Dmitry Matyushkin on 10.08.2021.
//

import SwiftUI
import Combine
import FactoryKit
import Observation

@MainActor
@Observable
final class ShoppingModel: AddShoppingListModelProtocol {
    
    @ObservationIgnored
    @Injected(\.dao) private var dao: DAOProtocol
    @ObservationIgnored
    @Injected(\.appEventCenter) private var appEvents
    
    var items: [ShoppingListModel] = []
    var showAddSheet: Bool = false
    var itemToOpen: ShoppingListModel?
    @ObservationIgnored
    private var cancellable = Set<AnyCancellable>()
    @ObservationIgnored
    private var reloadTask: Task<Void, Never>?
    
    init() {
        reloadItems()
        appEvents.shoppingListsDidChange
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] in
                self?.reloadItems()
            })
            .store(in: &cancellable)
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
                appEvents.showError(error, fallback: "Unable to load shopping lists")
            }
        }
    }
            
    func addItem(name: String) async {
        do {
            let item = try await dao.addShoppingList(name: name, date: Date())
            showAddSheet = false
            itemToOpen = item
            appEvents.shoppingListsChanged()
        } catch {
            appEvents.showError(error, fallback: "Unable to create shopping list")
        }
    }
    
    func cancelAddingItem() async {
        showAddSheet = false
    }

    func deleteItems(offsets: IndexSet) async {
        do {
            let itemsToDelete = items.enumerated().filter({ offsets.contains($0.offset) }).map({ $0.element })
            for item in itemsToDelete {
                try await dao.removeShoppingList(item)
            }
            appEvents.shoppingListsChanged()
        } catch {
            appEvents.showError(error, fallback: "Unable to delete shopping list")
        }
    }
}
