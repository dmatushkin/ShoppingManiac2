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
    
    func addGood(name: String, category: String) async throws {
        _ = try await dao.addGood(name: name, category: category)
        items = try await dao.getGoods()
        showAddSheet = false
    }
    
    func editGood(item: GoodsItemModel, name: String, category: String) async throws {
        _ = try await dao.editGood(item: item, name: name, category: category)
        items = try await dao.getGoods()
    }
}
