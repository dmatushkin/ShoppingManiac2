//
//  GoodsModel.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 27.10.2021.
//

import SwiftUI
import Factory
import Observation

@MainActor
@Observable
final class GoodsModel: EditGoodModelProtocol, Sendable {

    @ObservationIgnored
    @Injected(\.dao) private var dao: DAOProtocol
    
    var items: [GoodsItemModel] = []
    var showAddSheet: Bool = false
    var searchString: String = "" {
        didSet {
            reload()
        }
    }
    
    init() {
        Task {
            items = try await dao.getGoods(search: "")
        }
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
