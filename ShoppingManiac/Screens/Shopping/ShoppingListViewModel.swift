//
//  ShoppingListViewModel.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 26.10.2021.
//

import SwiftUI
import FactoryKit
import Observation

struct ExportedList: Identifiable {
    let id: String
    let url: URL
}

@MainActor
@Observable
final class ShoppingListViewModel: ShoppingListItemModelProtocol, EditShoppingListItemModelProtocol {
    
    @ObservationIgnored
    @Injected(\.dao) private var dao: DAOProtocol
    @ObservationIgnored
    @Injected(\.shoppingListSerializer) private var serializer: ShoppingListSerializerProtocol
    @ObservationIgnored
    @Injected(\.appEventCenter) private var appEvents
    
    var showAddSheet: Bool = false
    var showShareSheet: Bool = false
    var itemToShow: ShoppingListItemModel?
    var dataToShare: ExportedList?
    var output: ShoppingListOutput = ShoppingListOutput(sections: [], items: [])
    var isLoading: Bool = false
    
    @ObservationIgnored
    private let sorter = ShoppingListSorter()
    @ObservationIgnored
    private var reloadTask: Task<Void, Never>?
    @ObservationIgnored
    private var shareTask: Task<Void, Never>?
    
    var listModel: ShoppingListModel? {
        didSet {
            reloadList()
        }
    }
    
    deinit {
        reloadTask?.cancel()
        shareTask?.cancel()
    }
    
    func addShoppingListItem(model: EditShoppingListItemViewModel) async {
        guard let listModel = listModel else {
            appEvents.showError("Shopping list is unavailable", detail: nil)
            return
        }
        do {
            try await dao.addShoppingListItem(list: listModel,
                                              name: model.itemName,
                                              amount: model.amount,
                                              store: model.storeName,
                                              isWeight: model.amountType == 1,
                                              price: model.price,
                                              isImportant: model.isImportant,
                                              rating: model.rating,
                                              isPurchased: false)
            output = sorter.sort(try await dao.getShoppingListItems(list: listModel))
            showAddSheet = false
            appEvents.dataChanged()
        } catch {
            appEvents.showError(error, fallback: "Unable to add item")
        }
    }
    
    func editShoppingListItem(item: ShoppingListItemModel, model: EditShoppingListItemViewModel) async {
        guard let listModel = listModel else {
            appEvents.showError("Shopping list is unavailable", detail: nil)
            return
        }
        do {
            try await dao.editShoppingListItem(item: item,
                                               name: model.itemName,
                                               amount: model.amount,
                                               store: model.storeName,
                                               isWeight: model.amountType == 1,
                                               price: model.price,
                                               isImportant: model.isImportant,
                                               rating: model.rating)
            output = sorter.sort(try await dao.getShoppingListItems(list: listModel))
            itemToShow = nil
            appEvents.dataChanged()
        } catch {
            appEvents.showError(error, fallback: "Unable to save item")
        }
    }
        
    func cancelAddingItem() async {
        showAddSheet = false
        itemToShow = nil
    }
    
    func removeShoppingListItem(item: ShoppingListItemModel) async {
        guard let listModel = listModel else {
            appEvents.showError("Shopping list is unavailable", detail: nil)
            return
        }
        do {
            try await dao.removeShoppingListItem(item: item)
            let items = try await dao.getShoppingListItems(list: listModel)
            withAnimation {
                output = sorter.sort(items)
            }
        } catch {
            appEvents.showError(error, fallback: "Unable to delete item")
        }
    }

    func editItem(item: ShoppingListItemModel) async {
        itemToShow = item
    }
    
    func togglePurchased(item: ShoppingListItemModel) async {
        guard let listModel = listModel else {
            appEvents.showError("Shopping list is unavailable", detail: nil)
            return
        }
        do {
            try await dao.togglePurchasedShoppingListItem(item: item)
            output = sorter.sort(try await dao.getShoppingListItems(list: listModel))
        } catch {
            appEvents.showError(error, fallback: "Unable to update item")
        }
    }
        
    private func reloadList() {
        reloadTask?.cancel()
        guard let listModel = listModel else { return }
        reloadTask = Task {
            do {
                let items = try await dao.getShoppingListItems(list: listModel)
                try Task.checkCancellation()
                output = sorter.sort(items)
            } catch is CancellationError {
            } catch {
                appEvents.showError(error, fallback: "Unable to load shopping list")
            }
        }
    }
    
    func shareByFile(model: ShoppingListModel) {
        shareTask?.cancel()
        shareTask = Task {
            do {
                isLoading = true
                let data = try await serializer.exportList(listModel: model)
                try Task.checkCancellation()
                dataToShare = ExportedList(id: model.id, url: try data.store())
                isLoading = false
            } catch is CancellationError {
                isLoading = false
            } catch {
                isLoading = false
                appEvents.showError(error, fallback: "Unable to prepare export")
            }
        }
    }
}
