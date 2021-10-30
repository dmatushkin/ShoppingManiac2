//
//  ShoppingListViewModel.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 26.10.2021.
//

import SwiftUI
import Combine
import DependencyInjection

struct ShoppingListSection: Identifiable {
    var id: String { title }
    let title: String
    let subsections: [ShoppingListSection]
    let items: [ShoppingListItemModel]
}

struct ShoppingListOutput {
    let sections: [ShoppingListSection]
    let items: [ShoppingListItemModel]
}

protocol ShoppingListSorterProtocol {
    func sort(_ items: [ShoppingListItemModel]) -> ShoppingListOutput
}

final class ShoppingListSorter: DIDependency, ShoppingListSorterProtocol {
    
    private struct CategoryIntermediate: Hashable {
        let name: String
        let sortOrder: Int?
    }
    
    required init() {}
    
    func sort(_ items: [ShoppingListItemModel]) -> ShoppingListOutput {
        let stores = Array(Set(items.map({ $0.store }).filter({ !$0.isEmpty }))).sorted(by: { $0 < $1 })
        let noStoreItems = items.filter({ $0.store.isEmpty })
        let storeSections = stores.map({ storeName in
            categorySort(items.filter({ $0.store == storeName }), title: storeName)
        }).filter({ !$0.subsections.isEmpty || !$0.items.isEmpty })
        let noStoreSection = categorySort(noStoreItems, title: "")
        return ShoppingListOutput(sections: storeSections + noStoreSection.subsections, items: noStoreSection.items)
    }
    
    private func categorySort(_ items: [ShoppingListItemModel], title: String) -> ShoppingListSection {
        let categories = Array(Set(items.map({ CategoryIntermediate(name: $0.category, sortOrder: $0.categoryStoreOrder) })
                                    .filter({ !$0.name.isEmpty }))).sorted(by: {
            let sort1 = $0.sortOrder ?? Int.max
            let sort2 = $1.sortOrder ?? Int.max
            if sort1 == sort2 {
                return $0.name < $1.name
            } else {
                return sort1 < sort2
            }
        })
        let subsections = categories.map({ category in
            ShoppingListSection(title: category.name, subsections: [], items: nameAndPurchaseSort(items.filter({ $0.category == category.name })))
        })
        let noCategoryItems = nameAndPurchaseSort(items.filter({ $0.category.isEmpty }))
        return ShoppingListSection(title: title, subsections: subsections, items: noCategoryItems)
    }
    
    private func nameAndPurchaseSort(_ items: [ShoppingListItemModel]) -> [ShoppingListItemModel] {
        let purchasedItems = items.filter({ $0.isPurchased })
        let notPurchasedItems = items.filter({ !$0.isPurchased })
        return notPurchasedItems.sorted(by: { $0.title < $1.title }) + purchasedItems.sorted(by: { $0.title < $1.title })
    }
}

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
