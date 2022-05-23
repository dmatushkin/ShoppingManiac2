//
//  ShoppingListViewModel.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 26.10.2021.
//

import SwiftUI
import Combine
import DependencyInjection
import CoreData
import CloudKit

struct ExportedList: Identifiable {
    let id: NSManagedObjectID
    let url: URL
}

struct SharedList: Identifiable {
    let id: NSManagedObjectID
    let share: CKShare
    let container: CKContainer
}

@MainActor
final class ShoppingListViewModel: ObservableObject {
    
    @Autowired(cacheType: .share) private var dao: DAOProtocol
    @Autowired(cacheType: .share) private var serializer: ShoppingListSerializerProtocol
    
    @Published var showAddSheet: Bool = false
    @Published var showShareSheet: Bool = false
    @Published var itemToShow: ShoppingListItemModel?
    @Published var dataToShare: ExportedList?
    @Published var sharedList: SharedList?
    @Published var output: ShoppingListOutput = ShoppingListOutput(sections: [], items: [])
    
    private let sorter = ShoppingListSorter()
    
    var listModel: ShoppingListModel? {
        didSet {
            Task {
                try await reloadList()
            }
        }
    }
    
    func addShoppingListItem(model: EditShoppingListItemViewModel) async throws {
        showAddSheet = false
        guard let listModel = listModel else { return }
        try await dao.addShoppingListItem(list: listModel,
                                          name: model.itemName,
                                          amount: model.amount,
                                          store: model.storeName,
                                          isWeight: model.amountType == 1,
                                          price: model.price,
                                          isImportant: model.isImportant,
                                          rating: model.rating,
                                          isPurchased: false,
                                          uniqueId: nil)
        output = sorter.sort(try await dao.getShoppingListItems(list: listModel))
    }
    
    func editShoppingListItem(item: ShoppingListItemModel, model: EditShoppingListItemViewModel) async throws {
        
        guard let listModel = listModel else { return }
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
    
    func shareByFile(model: ShoppingListModel) {
        Task {
            do {
                let data = try await serializer.exportList(listModel: model)
                dataToShare = ExportedList(id: model.id, url: try data.store())
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func shareByiCloud(model: ShoppingListModel) {
        Task {
            do {
                if let itemShare = try await PersistenceController.shared.getShare(model),
                    let container = PersistenceController.shared.ckContainer {
                    sharedList = SharedList(id: model.id, share: itemShare, container: container)
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}
