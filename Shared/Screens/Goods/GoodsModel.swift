//
//  GoodsModel.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 27.10.2021.
//

import SwiftUI
import Combine
import DependencyInjection

@MainActor
final class GoodsModel: ObservableObject, EditGoodModelProtocol, Sendable {

    @Autowired(cacheType: .share) private var dao: DAOProtocol
    
    @Published var items: [GoodsItemModel] = []
    @Published var showAddSheet: Bool = false
    @Published var searchString: String = ""
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        Task {
            items = try await dao.getGoods(search: "")
        }
        $searchString.sink(receiveValue: {[weak self] value in
            guard let self = self else { return }
            Task {
                self.items = try await self.dao.getGoods(search: value)
            }
        }).store(in: &cancellables)
    }
    
    func reload() {
        Task {
            items = try await dao.getGoods(search: searchString)
        }
    }
        
    func editGood(item: GoodsItemModel?, name: String, category: String) async throws {
        if let item = item {
            _ = try await dao.editGood(item: item, name: name, category: category)
        } else {
            _ = try await dao.addGood(name: name, category: category)
        }        
        items = try await dao.getGoods(search: searchString)
    }
    
    func removeGood(offsets: IndexSet) async throws {
        let itemsToDelete = items.enumerated().filter({ offsets.contains($0.offset) }).map({ $0.element })
        for item in itemsToDelete {
            try await dao.removeGood(item: item)
        }
        items = try await dao.getGoods(search: searchString)
    }
}
