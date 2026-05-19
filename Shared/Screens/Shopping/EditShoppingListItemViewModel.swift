//
//  EditShoppingListItemViewModel.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 01.11.2021.
//

import Foundation
import Factory
import Observation

@MainActor
@Observable
final class EditShoppingListItemViewModel {
    var itemName: String = "" {
        didSet {
            reloadGoods()
        }
    }
    var storeName: String = "" {
        didSet {
            reloadStores()
        }
    }
    var amount: String = ""
    var amountType: Int = 0
    var price: String = ""
    var isImportant: Bool = false
    var rating: Int = 0
    var goodsNames: [String] = []
    var storesNames: [String] = []
    @ObservationIgnored
    @Injected(\.dao) private var dao: DAOProtocol
    
    private func reloadGoods() {
        Task {
            goodsNames = try await dao.getGoods(search: itemName).map({ $0.name })
        }
    }
    
    private func reloadStores() {
        Task {
            storesNames = try await dao.getStores(search: storeName).map({ $0.name })
        }
    }
    
    func setItem(_ item: ShoppingListItemModel?) {
        if let item = item {
            itemName = item.title
            storeName = item.store
            amount = item.amount
            amountType = item.isWeight ? 1 : 0
            price = item.price
            isImportant = item.isImportant
            rating = item.rating
        } else {
            itemName = ""
            storeName = ""
            amount = ""
            amountType = 0
            price = ""
            isImportant = false
            rating = 0
        }
    }
}
