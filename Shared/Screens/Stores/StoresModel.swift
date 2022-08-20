//
//  StoresModel.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 27.10.2021.
//

import SwiftUI
import Combine
import DependencyInjection

@MainActor
final class StoresModel: ObservableObject, EditStoreModelProtocol {
    
    @Autowired(cacheType: .share) private var dao: DAOProtocol
    
    @Published var items: [StoresItemModel] = []
    @Published var showAddSheet: Bool = false
    @Published var searchString: String = ""
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        Task {
            items = try await dao.getStores(search: "")
        }
        $searchString.sink(receiveValue: {[weak self] value in
            guard let self = self else { return }
            Task {
                self.items = try await self.dao.getStores(search: value)
            }
        }).store(in: &cancellables)
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
