//
//  StoresModel.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 27.10.2021.
//

import SwiftUI
import Factory
import Observation

@MainActor
@Observable
final class StoresModel: EditStoreModelProtocol {
    
    @ObservationIgnored
    @Injected(\.dao) private var dao: DAOProtocol
    
    var items: [StoresItemModel] = []
    var showAddSheet: Bool = false
    var searchString: String = "" {
        didSet {
            reload()
        }
    }
    
    init() {
        Task {
            items = try await dao.getStores(search: "")
        }
    }
    
    func reload() {
        Task {
            items = try await dao.getStores(search: searchString)
        }
    }
        
    func editStore(item: StoresItemModel?, name: String, categories: [String]) async throws {
        if let item = item {
            let store = try await dao.editStore(item: item, name: name)
            try await dao.syncStoreCategories(item: store, categories: categories)
        } else {
            let store = try await dao.addStore(name: name)
            try await dao.syncStoreCategories(item: store, categories: categories)
        }        
        items = try await dao.getStores(search: searchString)
    }
    
    func removeStore(offsets: IndexSet) async throws {
        let itemsToDelete = items.enumerated().filter({ offsets.contains($0.offset) }).map({ $0.element })
        for item in itemsToDelete {
            try await dao.removeStore(item: item)
        }
        items = try await dao.getStores(search: searchString)
    }
    
    func getStoreCategories(item: StoresItemModel) async throws -> [CategoriesItemModel] {
        return try await dao.getStoreCategories(item: item)
    }
}
