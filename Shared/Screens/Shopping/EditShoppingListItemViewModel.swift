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
    @ObservationIgnored
    private var goodsReloadTask: Task<Void, Never>?
    @ObservationIgnored
    private var storesReloadTask: Task<Void, Never>?
    
    deinit {
        goodsReloadTask?.cancel()
        storesReloadTask?.cancel()
    }
    
    private func reloadGoods() {
        goodsReloadTask?.cancel()
        let search = itemName
        goodsReloadTask = Task {
            do {
                let names = try await dao.getGoods(search: search).map({ $0.name })
                try Task.checkCancellation()
                goodsNames = names
            } catch is CancellationError {
            } catch {
            }
        }
    }
    
    private func reloadStores() {
        storesReloadTask?.cancel()
        let search = storeName
        storesReloadTask = Task {
            do {
                let names = try await dao.getStores(search: search).map({ $0.name })
                try Task.checkCancellation()
                storesNames = names
            } catch is CancellationError {
            } catch {
            }
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
