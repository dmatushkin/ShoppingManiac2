//
//  EditShoppingListItemViewModel.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 01.11.2021.
//

import Foundation
import Combine
import DependencyInjection

@MainActor
final class EditShoppingListItemViewModel: ObservableObject {
    @Published var itemName: String = ""
    @Published var storeName: String = ""
    @Published var amount: String = ""
    @Published var amountType: Int = 0
    @Published var price: String = ""
    @Published var isImportant: Bool = false
    @Published var rating: Int = 0
    @Published var goodsNames: [String] = []
    @Published var storesNames: [String] = []
    private var cancellables = Set<AnyCancellable>()
    @Autowired(cacheType: .share) private var dao: DAOProtocol
    
    init() {
        $itemName.sink(receiveValue: {value in
            Task { [weak self] in
                self?.goodsNames = try await self?.dao.getGoods(search: value).map({ $0.name }) ?? []
            }
        }).store(in: &cancellables)
        $storeName.sink(receiveValue: {value in
            Task { [weak self] in
                self?.storesNames = try await self?.dao.getStores(search: value).map({ $0.name }) ?? []
            }
        }).store(in: &cancellables)
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
