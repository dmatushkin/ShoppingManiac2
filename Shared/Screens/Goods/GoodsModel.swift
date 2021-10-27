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
final class GoodsModel: ObservableObject {
    
    @Autowired(cacheType: .share) private var dao: DAOProtocol
    
    @Published var items: [GoodsItemModel] = []
    @Published var showAddSheet: Bool = false
    
    init() {
        Task {
            items = try await dao.getGoods()
        }
    }
        
    func editGood(item: GoodsItemModel?, name: String, category: String) async throws {
        if let item = item {
            _ = try await dao.editGood(item: item, name: name, category: category)
        } else {
            _ = try await dao.addGood(name: name, category: category)
        }        
        items = try await dao.getGoods()
    }
    
    func removeGood(offsets: IndexSet) async throws {
        let itemsToDelete = items.enumerated().filter({ offsets.contains($0.offset) }).map({ $0.element })
        for item in itemsToDelete {
            try await dao.removeGood(item: item)
        }
        items = try await dao.getGoods()
    }
}
