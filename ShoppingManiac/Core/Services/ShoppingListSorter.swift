//
//  ShoppingListSorter.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 01.11.2021.
//

import Foundation
import FactoryKit

struct ShoppingListSection: Identifiable, Sendable {
    let id: String
    let title: String
    let isStore: Bool
    let subsections: [ShoppingListSection]
    let items: [ShoppingListItemModel]
}

struct ShoppingListOutput: Sendable {
    let sections: [ShoppingListSection]
    let items: [ShoppingListItemModel]
}

protocol ShoppingListSorterProtocol {
    func sort(_ items: [ShoppingListItemModel]) -> ShoppingListOutput
}

final class ShoppingListSorter: ShoppingListSorterProtocol {
    
    private struct CategoryIntermediate: Hashable {
        let name: String
        let sortOrder: Int?
    }
    
    required init() {}
    
    func sort(_ items: [ShoppingListItemModel]) -> ShoppingListOutput {
        var itemsByStore: [String: [ShoppingListItemModel]] = [:]
        var noStoreItems: [ShoppingListItemModel] = []

        for item in items {
            if item.store.isEmpty {
                noStoreItems.append(item)
            } else {
                itemsByStore[item.store, default: []].append(item)
            }
        }

        let storeSections = itemsByStore.keys.sorted().map { storeName in
            categorySort(itemsByStore[storeName, default: []], id: "store:\(storeName)", title: storeName)
        }.filter { !$0.subsections.isEmpty || !$0.items.isEmpty }
        let noStoreSection = categorySort(noStoreItems, id: "no-store", title: "")
        return ShoppingListOutput(sections: storeSections + noStoreSection.subsections, items: noStoreSection.items)
    }
    
    private func categorySort(_ items: [ShoppingListItemModel], id: String, title: String) -> ShoppingListSection {
        var itemsByCategory: [CategoryIntermediate: [ShoppingListItemModel]] = [:]
        var noCategoryItems: [ShoppingListItemModel] = []

        for item in items {
            if item.category.isEmpty {
                noCategoryItems.append(item)
            } else {
                let category = CategoryIntermediate(name: item.category, sortOrder: item.categoryStoreOrder)
                itemsByCategory[category, default: []].append(item)
            }
        }

        let categories = itemsByCategory.keys.sorted {
            let lhsSortOrder = $0.sortOrder ?? Int.max
            let rhsSortOrder = $1.sortOrder ?? Int.max
            if lhsSortOrder == rhsSortOrder {
                return $0.name < $1.name
            } else {
                return lhsSortOrder < rhsSortOrder
            }
        }
        let subsections = categories.map { category in
            let sortOrderID = category.sortOrder.map(String.init) ?? "none"
            return ShoppingListSection(id: "\(id)/category:\(category.name)/order:\(sortOrderID)",
                                       title: category.name,
                                       isStore: false,
                                       subsections: [],
                                       items: nameAndPurchaseSort(itemsByCategory[category, default: []]))
        }
        let sortedNoCategoryItems = nameAndPurchaseSort(noCategoryItems)
        return ShoppingListSection(id: id, title: title, isStore: true, subsections: subsections, items: sortedNoCategoryItems)
    }
    
    private func nameAndPurchaseSort(_ items: [ShoppingListItemModel]) -> [ShoppingListItemModel] {
        items.sorted {
            if $0.isPurchased == $1.isPurchased {
                return $0.title < $1.title
            } else {
                return !$0.isPurchased
            }
        }
    }
}
